import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Placeholder home for the `transport` role.
/// TODO: replace with event list + mobilised/attended/cost form.
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
      body: const Center(child: Text('Transport home — coming next.')),
    );
  }
}
