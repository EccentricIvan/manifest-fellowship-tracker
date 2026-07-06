import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Placeholder home for the `callCentre` role.
/// TODO: replace with a stream of assignments where assignedTo == current uid.
class CallCentreHomeScreen extends StatelessWidget {
  const CallCentreHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
      body: const Center(child: Text('Call centre home — coming next.')),
    );
  }
}
