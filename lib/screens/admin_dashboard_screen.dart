import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/assignment_model.dart';
import '../models/session_model.dart';
import 'assign_calls_screen.dart';
import 'manage_users_screen.dart';
import 'members_register_screen.dart';

class _WeekBucket {
  final DateTime weekStart;
  int totalAttendance = 0;
  int year1Count = 0;

  _WeekBucket(this.weekStart);
}

class _DashboardStats {
  final List<_WeekBucket> weeks;
  final int thisWeekTotal;
  final int lastWeekTotal;
  final int callsDone;
  final int callsTotal;
  final int pendingFirstTimerFollowUps;

  _DashboardStats({
    required this.weeks,
    required this.thisWeekTotal,
    required this.lastWeekTotal,
    required this.callsDone,
    required this.callsTotal,
    required this.pendingFirstTimerFollowUps,
  });

  double get callCompletionRate => callsTotal == 0 ? 0 : callsDone / callsTotal;
}

DateTime _startOfWeek(DateTime d) {
  final date = DateTime(d.year, d.month, d.day);
  return date.subtract(Duration(days: date.weekday - 1));
}

Future<_DashboardStats> _loadStats() async {
  final sessionsSnap = await FirebaseFirestore.instance
      .collection('sessions')
      .orderBy('date', descending: true)
      .limit(120)
      .get();
  final sessions = sessionsSnap.docs.map(FellowshipSession.fromDoc).toList();

  final buckets = <DateTime, _WeekBucket>{};
  for (final s in sessions) {
    final weekStart = _startOfWeek(s.date);
    final bucket = buckets.putIfAbsent(weekStart, () => _WeekBucket(weekStart));
    bucket.totalAttendance += s.totalAttendance;
    bucket.year1Count += s.year1Count;
  }
  final sortedWeeks = buckets.values.toList()
    ..sort((a, b) => a.weekStart.compareTo(b.weekStart));
  final recentWeeks =
      sortedWeeks.length > 6 ? sortedWeeks.sublist(sortedWeeks.length - 6) : sortedWeeks;

  final thisWeekStart = _startOfWeek(DateTime.now());
  final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
  final thisWeekTotal = buckets[thisWeekStart]?.totalAttendance ?? 0;
  final lastWeekTotal = buckets[lastWeekStart]?.totalAttendance ?? 0;

  final assignmentsSnap =
      await FirebaseFirestore.instance.collection('assignments').get();
  final assignments = assignmentsSnap.docs.map(Assignment.fromDoc).toList();
  final callsTotal = assignments.length;
  final callsDone =
      assignments.where((a) => a.status == AssignmentStatus.done).length;
  final pendingFirstTimerFollowUps = assignments
      .where((a) =>
          a.reason == AssignmentReason.firstTimer &&
          a.status == AssignmentStatus.pending)
      .length;

  return _DashboardStats(
    weeks: recentWeeks,
    thisWeekTotal: thisWeekTotal,
    lastWeekTotal: lastWeekTotal,
    callsDone: callsDone,
    callsTotal: callsTotal,
    pendingFirstTimerFollowUps: pendingFirstTimerFollowUps,
  );
}

/// Home for the `admin` and `leader` roles: attendance trends, call
/// completion rate, pending follow-ups, and management shortcuts.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<_DashboardStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _loadStats();
  }

  Future<void> _refresh() async {
    setState(() => _statsFuture = _loadStats());
    await _statsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_DashboardStats>(
          future: _statsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final stats = snapshot.data!;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AttendanceComparisonRow(stats: stats),
                const SizedBox(height: 24),
                Text(
                  'Attendance — Last ${stats.weeks.length} Weeks',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: _AttendanceBarChart(weeks: stats.weeks),
                ),
                const SizedBox(height: 24),
                Text(
                  'Year 1 Trend',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: _Year1LineChart(weeks: stats.weeks),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        label: 'Call Completion Rate',
                        value:
                            '${(stats.callCompletionRate * 100).toStringAsFixed(0)}%',
                        subtitle: '${stats.callsDone} of ${stats.callsTotal} calls',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        label: 'Pending First-Timer Follow-ups',
                        value: '${stats.pendingFirstTimerFollowUps}',
                        subtitle: 'awaiting a call',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.groups),
                    title: const Text('Members Register'),
                    subtitle: const Text('Search, add, and edit members'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MembersRegisterScreen(),
                      ),
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.manage_accounts),
                    title: const Text('Manage Users'),
                    subtitle: const Text('View and edit roles'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.assignment_ind),
                    title: const Text('Assign Calls'),
                    subtitle: const Text('Create and track follow-up calls'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AssignCallsScreen()),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AttendanceComparisonRow extends StatelessWidget {
  final _DashboardStats stats;

  const _AttendanceComparisonRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final delta = stats.thisWeekTotal - stats.lastWeekTotal;
    return Row(
      children: [
        Expanded(
          child: _StatCard(label: 'This Week', value: '${stats.thisWeekTotal}'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(label: 'Last Week', value: '${stats.lastWeekTotal}'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Change',
            value: '${delta >= 0 ? '+' : ''}$delta',
            valueColor: delta >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: valueColor,
                  ),
            ),
            if (subtitle != null)
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

Widget _weekAxisLabel(List<_WeekBucket> weeks, double value, TitleMeta meta) {
  final index = value.toInt();
  if (index < 0 || index >= weeks.length) return const SizedBox();
  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      DateFormat.Md().format(weeks[index].weekStart),
      style: const TextStyle(fontSize: 10),
    ),
  );
}

class _AttendanceBarChart extends StatelessWidget {
  final List<_WeekBucket> weeks;

  const _AttendanceBarChart({required this.weeks});

  @override
  Widget build(BuildContext context) {
    if (weeks.isEmpty) {
      return const Center(child: Text('No session data yet.'));
    }
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => _weekAxisLabel(weeks, value, meta),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < weeks.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: weeks[i].totalAttendance.toDouble(),
                  color: Theme.of(context).colorScheme.primary,
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Year1LineChart extends StatelessWidget {
  final List<_WeekBucket> weeks;

  const _Year1LineChart({required this.weeks});

  @override
  Widget build(BuildContext context) {
    if (weeks.isEmpty) {
      return const Center(child: Text('No session data yet.'));
    }
    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => _weekAxisLabel(weeks, value, meta),
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < weeks.length; i++)
                FlSpot(i.toDouble(), weeks[i].year1Count.toDouble()),
            ],
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
