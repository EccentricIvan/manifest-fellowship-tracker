import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/assignment_model.dart';
import 'create_assignment_screen.dart';

class AssignCallsScreen extends StatelessWidget {
  const AssignCallsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Calls')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('assignments')
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
            return const Center(child: Text('No assignments yet.'));
          }

          return ListView.separated(
            itemCount: assignments.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                _AssignmentRow(assignment: assignments[index]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateAssignmentScreen()),
        ),
        icon: const Icon(Icons.add_task),
        label: const Text('New Assignment'),
      ),
    );
  }
}

class _AssignmentRow extends StatelessWidget {
  final Assignment assignment;

  const _AssignmentRow({required this.assignment});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
      future: Future.wait([
        FirebaseFirestore.instance
            .collection('members')
            .doc(assignment.memberId)
            .get(),
        FirebaseFirestore.instance
            .collection('users')
            .doc(assignment.assignedTo)
            .get(),
      ]),
      builder: (context, snapshot) {
        final memberDoc = snapshot.data?[0];
        final userDoc = snapshot.data?[1];
        final memberName =
            (memberDoc?.exists ?? false) ? memberDoc!.data()!['name'] : '…';
        final assigneeName =
            (userDoc?.exists ?? false) ? userDoc!.data()!['name'] : '…';
        final isDone = assignment.status == AssignmentStatus.done;

        return ListTile(
          title: Text('$memberName → $assigneeName'),
          subtitle: Text(
            '${assignment.reason.name} · due ${DateFormat.MMMd().format(assignment.dueDate)}',
          ),
          trailing: Chip(
            label: Text(isDone ? 'Done' : 'Pending'),
            backgroundColor: isDone
                ? Colors.green.withValues(alpha: 0.15)
                : Colors.orange.withValues(alpha: 0.15),
          ),
        );
      },
    );
  }
}
