import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Placeholder home for the `admin` and `leader` roles.
/// TODO: replace with attendance trends, call-completion rate,
/// pending follow-ups, and user/role management.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

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
      body: const Center(child: Text('Admin dashboard — coming next.')),
    );
  }
}
