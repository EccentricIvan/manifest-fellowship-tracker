import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event_model.dart';
import 'record_event_screen.dart';

class TransportHomeScreen extends StatelessWidget {
  const TransportHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transport'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .orderBy('date', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final events = snapshot.data?.docs ?? [];
          if (events.isEmpty) {
            return const Center(child: Text('No events recorded yet.'));
          }
          return ListView.separated(
            itemCount: events.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final event = FellowshipEvent.fromDoc(events[index]);
              return ListTile(
                title: Text(event.name),
                subtitle: Text(
                  '${DateFormat.yMMMd().format(event.date)} · Mobilised: ${event.mobilisedCount} · Attended: ${event.attendedCount} · Cost: ${event.transportCost.toStringAsFixed(0)}',
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RecordEventScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Record Event'),
      ),
    );
  }
}
