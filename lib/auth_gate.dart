import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/user_model.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/call_centre_home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/pending_approval_screen.dart';
import 'screens/transport_home_screen.dart';
import 'screens/usher_home_screen.dart';

/// Listens to auth state, then looks up the signed-in user's role in
/// `/users/{uid}` and routes to the matching home screen. If no user doc
/// exists yet, shows [PendingApprovalScreen].
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingScreen();
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userDocSnapshot) {
            if (userDocSnapshot.connectionState == ConnectionState.waiting) {
              return const _LoadingScreen();
            }

            final doc = userDocSnapshot.data;
            if (doc == null || !doc.exists) {
              return const PendingApprovalScreen();
            }

            final appUser = AppUser.fromDoc(doc);
            switch (appUser.role) {
              case UserRole.admin:
              case UserRole.leader:
                return const AdminDashboardScreen();
              case UserRole.usher:
                return const UsherHomeScreen();
              case UserRole.callCentre:
                return const CallCentreHomeScreen();
              case UserRole.transport:
                return const TransportHomeScreen();
            }
          },
        );
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
