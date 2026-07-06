import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Placeholder home for the `usher` role.
/// TODO: replace with recent sessions list + "Record Session" form.
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
      body: const Center(child: Text('Usher home — coming next.')),
    );
  }
}
