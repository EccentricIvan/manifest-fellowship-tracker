import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/assignment_model.dart';
import '../models/member_model.dart';
import '../models/user_model.dart';

class CreateAssignmentScreen extends StatefulWidget {
  const CreateAssignmentScreen({super.key});

  @override
  State<CreateAssignmentScreen> createState() =>
      _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  Member? _selectedMember;
  AppUser? _selectedAssignee;
  AssignmentReason _reason = AssignmentReason.firstTimer;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 2));
  bool _isSaving = false;

  Future<void> _pickMember() async {
    final member = await showDialog<Member>(
      context: context,
      builder: (_) => const _MemberPickerDialog(),
    );
    if (member != null) setState(() => _selectedMember = member);
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (_selectedMember == null || _selectedAssignee == null) return;
    setState(() => _isSaving = true);
    try {
      final assignment = Assignment(
        id: '',
        memberId: _selectedMember!.id,
        assignedTo: _selectedAssignee!.uid,
        reason: _reason,
        status: AssignmentStatus.pending,
        dueDate: _dueDate,
      );
      await FirebaseFirestore.instance
          .collection('assignments')
          .add(assignment.toMap());
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Assignment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Member'),
            subtitle: Text(_selectedMember?.name ?? 'Tap to select'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickMember,
          ),
          const Divider(),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'callCentre')
                .snapshots(),
            builder: (context, snapshot) {
              final callers =
                  (snapshot.data?.docs ?? []).map(AppUser.fromDoc).toList();
              return DropdownButtonFormField<AppUser>(
                initialValue: _selectedAssignee,
                decoration: const InputDecoration(labelText: 'Assign To'),
                items: callers
                    .map(
                      (u) => DropdownMenuItem(
                        value: u,
                        child: Text(u.name.isEmpty ? u.uid : u.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _selectedAssignee = value),
              );
            },
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<AssignmentReason>(
            initialValue: _reason,
            decoration: const InputDecoration(labelText: 'Reason'),
            items: const [
              DropdownMenuItem(
                value: AssignmentReason.firstTimer,
                child: Text('First-timer'),
              ),
              DropdownMenuItem(
                value: AssignmentReason.absent,
                child: Text('Absent'),
              ),
              DropdownMenuItem(
                value: AssignmentReason.pastoral,
                child: Text('Pastoral'),
              ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _reason = value);
            },
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Due Date'),
            subtitle: Text(DateFormat.yMMMd().format(_dueDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDueDate,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed:
                (_selectedMember != null && _selectedAssignee != null && !_isSaving)
                    ? _save
                    : null,
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Assignment'),
          ),
        ],
      ),
    );
  }
}

class _MemberPickerDialog extends StatefulWidget {
  const _MemberPickerDialog();

  @override
  State<_MemberPickerDialog> createState() => _MemberPickerDialogState();
}

class _MemberPickerDialogState extends State<_MemberPickerDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 400,
        height: 500,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search members',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream:
                    FirebaseFirestore.instance.collection('members').snapshots(),
                builder: (context, snapshot) {
                  final members = (snapshot.data?.docs ?? [])
                      .map(Member.fromDoc)
                      .where((m) =>
                          _query.isEmpty || m.name.toLowerCase().contains(_query))
                      .toList()
                    ..sort((a, b) => a.name.compareTo(b.name));
                  return ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      return ListTile(
                        title: Text(member.name),
                        subtitle: Text(member.phone),
                        onTap: () => Navigator.of(context).pop(member),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
