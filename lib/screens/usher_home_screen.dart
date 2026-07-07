import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/session_model.dart';
import 'record_session_screen.dart';

class UsherHomeScreen extends StatelessWidget {
  const UsherHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usher'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .orderBy('date', descending: true)
            .limit(30)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No sessions recorded yet.'));
          }
          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final session = FellowshipSession.fromDoc(docs[index]);
              return ListTile(
                title: Text(
                  '${session.type.name[0].toUpperCase()}${session.type.name.substring(1)} — ${DateFormat.yMMMd().format(session.date)}',
                ),
                subtitle: Text(
                  'Total: ${session.totalAttendance} · Y1: ${session.year1Count} · Y2: ${session.year2Count} · Y3+: ${session.year3PlusCount} · Visitors: ${session.visitorsCount}',
                ),
                trailing: session.newBelieversCount > 0
                    ? Chip(label: Text('${session.newBelieversCount} new'))
                    : null,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RecordSessionScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Record Session'),
      ),
    );
  }
}
