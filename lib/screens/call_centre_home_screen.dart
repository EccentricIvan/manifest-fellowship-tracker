import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/assignment_model.dart';
import '../models/call_log_model.dart';
import '../models/member_model.dart';

class CallCentreHomeScreen extends StatelessWidget {
  const CallCentreHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Centre'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .where('assignedTo', isEqualTo: uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final assignments = (snapshot.data?.docs ?? [])
              .map(Assignment.fromDoc)
              .toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

          if (assignments.isEmpty) {
            return const Center(child: Text('No assignments right now.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(8),
            itemCount: assignments.length,
            separatorBuilder: (_, _) => const SizedBox(height: 4),
            itemBuilder: (context, index) =>
                _AssignmentCard(assignment: assignments[index]),
          );
        },
      ),
    );
  }
}

String _outcomeLabel(CallOutcome outcome) {
  switch (outcome) {
    case CallOutcome.reached:
      return 'Reached';
    case CallOutcome.noAnswer:
      return 'No Answer';
    case CallOutcome.needsVisit:
      return 'Needs Visit';
    case CallOutcome.prayedWith:
      return 'Prayed With';
  }
}

String _reasonLabel(AssignmentReason reason) {
  switch (reason) {
    case AssignmentReason.firstTimer:
      return 'First-timer';
    case AssignmentReason.absent:
      return 'Absent';
    case AssignmentReason.pastoral:
      return 'Pastoral';
  }
}

class _AssignmentCard extends StatelessWidget {
  final Assignment assignment;

  const _AssignmentCard({required this.assignment});

  Future<void> _call(BuildContext context, String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open dialer')),
      );
    }
  }

  Future<void> _recordOutcome(BuildContext context, CallOutcome outcome) async {
    final noteController = TextEditingController();
    bool followUpNeeded = outcome == CallOutcome.needsVisit;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text('Log call — ${_outcomeLabel(outcome)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: followUpNeeded,
                title: const Text('Follow-up needed'),
                onChanged: (v) =>
                    setDialogState(() => followUpNeeded = v ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final callLog = CallLog(
      id: '',
      memberId: assignment.memberId,
      calledBy: uid,
      date: DateTime.now(),
      outcome: outcome,
      note: noteController.text.trim(),
      followUpNeeded: followUpNeeded,
    );
    await FirebaseFirestore.instance
        .collection('callLogs')
        .add(callLog.toMap());
    await FirebaseFirestore.instance
        .collection('assignments')
        .doc(assignment.id)
        .update({'status': 'done'});
  }

  @override
  Widget build(BuildContext context) {
    final isDone = assignment.status == AssignmentStatus.done;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance
              .collection('members')
              .doc(assignment.memberId)
              .get(),
          builder: (context, memberSnapshot) {
            if (!memberSnapshot.hasData) {
              return const SizedBox(
                height: 60,
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final doc = memberSnapshot.data!;
            if (!doc.exists) {
              return const Text('Member not found');
            }
            final member = Member.fromDoc(doc);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${_reasonLabel(assignment.reason)} · due ${DateFormat.MMMd().format(assignment.dueDate)}',
                          ),
                        ],
                      ),
                    ),
                    if (isDone)
                      const Chip(label: Text('Done'))
                    else
                      IconButton(
                        icon: const Icon(Icons.call),
                        onPressed: () => _call(context, member.phone),
                      ),
                  ],
                ),
                if (!isDone) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: CallOutcome.values
                        .map(
                          (o) => OutlinedButton(
                            onPressed: () => _recordOutcome(context, o),
                            child: Text(_outcomeLabel(o)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}
