import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/member_model.dart';

/// A fast quick-add form for registering a first-timer during a session,
/// stripped down to the essentials so ushers/leaders can add several in a row.
class FirstTimerQuickAddScreen extends StatefulWidget {
  const FirstTimerQuickAddScreen({super.key});

  @override
  State<FirstTimerQuickAddScreen> createState() =>
      _FirstTimerQuickAddScreenState();
}

class _FirstTimerQuickAddScreenState extends State<FirstTimerQuickAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _gender = 'Male';
  Campus _campus = Campus.victoria;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveAndAddAnother() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final member = Member(
        id: '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: _gender,
        yearOfStudy: 1,
        course: '',
        campus: _campus,
        dateJoined: DateTime.now(),
        status: MemberStatus.active,
        tags: const ['firstTimer'],
      );
      await FirebaseFirestore.instance.collection('members').add(member.toMap());
      _nameController.clear();
      _phoneController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${member.name} added')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First-Timer Quick Add'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a phone number' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender'),
              items: const ['Male', 'Female']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _gender = v);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Campus>(
              initialValue: _campus,
              decoration: const InputDecoration(labelText: 'Campus'),
              items: Campus.values
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c == Campus.victoria ? 'Victoria' : 'Makerere'),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _campus = v);
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _saveAndAddAnother,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add & Add Another'),
            ),
          ],
        ),
      ),
    );
  }
}
