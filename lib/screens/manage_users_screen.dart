import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';

class ManageUsersScreen extends StatelessWidget {
  const ManageUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Users')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = (snapshot.data?.docs ?? []).map(AppUser.fromDoc).toList();
          if (users.isEmpty) {
            return const Center(child: Text('No users yet.'));
          }
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = users[index];
              return ListTile(
                title: Text(user.name.isEmpty ? '(no name)' : user.name),
                subtitle: Text('${user.phone} · ${user.role.name}'),
                onTap: () => _showEditUserDialog(context, user: user),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showEditUserDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('Add User'),
      ),
    );
  }
}

Future<void> _showEditUserDialog(BuildContext context, {AppUser? user}) async {
  final uidController = TextEditingController(text: user?.uid ?? '');
  final nameController = TextEditingController(text: user?.name ?? '');
  final phoneController = TextEditingController(text: user?.phone ?? '');
  final linkedMemberIdController =
      TextEditingController(text: user?.linkedMemberId ?? '');
  UserRole role = user?.role ?? UserRole.usher;
  final isEditing = user != null;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) => AlertDialog(
        title: Text(isEditing ? 'Edit User' : 'Add User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: uidController,
                enabled: !isEditing,
                decoration: const InputDecoration(
                  labelText: 'Auth UID',
                  helperText: 'Copy from Firebase Console → Authentication',
                ),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              DropdownButtonFormField<UserRole>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: UserRole.values
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.name)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) setDialogState(() => role = value);
                },
              ),
              TextField(
                controller: linkedMemberIdController,
                decoration:
                    const InputDecoration(labelText: 'Linked Member ID (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final uid = uidController.text.trim();
              if (uid.isEmpty) return;
              final data = AppUser(
                uid: uid,
                name: nameController.text.trim(),
                phone: phoneController.text.trim(),
                role: role,
                linkedMemberId: linkedMemberIdController.text.trim().isEmpty
                    ? null
                    : linkedMemberIdController.text.trim(),
              ).toMap();
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .set(data);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
