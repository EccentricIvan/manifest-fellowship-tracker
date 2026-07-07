import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/member_model.dart';

/// Full add/edit form for a member. Pass an existing [member] to edit it,
/// or leave null to create a new one.
class MemberFormScreen extends StatefulWidget {
  final Member? member;

  const MemberFormScreen({super.key, this.member});

  @override
  State<MemberFormScreen> createState() => _MemberFormScreenState();
}

class _MemberFormScreenState extends State<MemberFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _courseController;
  String _gender = 'Male';
  int _yearOfStudy = 1;
  Campus _campus = Campus.victoria;
  MemberStatus _status = MemberStatus.active;
  late DateTime _dateJoined;
  late Set<String> _tags;
  bool _isSaving = false;

  static const _availableTags = ['firstTimer', 'newBeliever', 'leader'];

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _nameController = TextEditingController(text: m?.name ?? '');
    _phoneController = TextEditingController(text: m?.phone ?? '');
    _courseController = TextEditingController(text: m?.course ?? '');
    _gender = m?.gender ?? 'Male';
    _yearOfStudy = m?.yearOfStudy ?? 1;
    _campus = m?.campus ?? Campus.victoria;
    _status = m?.status ?? MemberStatus.active;
    _dateJoined = m?.dateJoined ?? DateTime.now();
    _tags = {...(m?.tags ?? const [])};
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _courseController.dispose();
    super.dispose();
  }

  Future<void> _pickDateJoined() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateJoined,
      firstDate: DateTime(2015),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dateJoined = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final member = Member(
        id: widget.member?.id ?? '',
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        gender: _gender,
        yearOfStudy: _yearOfStudy,
        course: _courseController.text.trim(),
        campus: _campus,
        dateJoined: _dateJoined,
        status: _status,
        tags: _tags.toList(),
      );
      final collection = FirebaseFirestore.instance.collection('members');
      if (widget.member == null) {
        await collection.add(member.toMap());
      } else {
        await collection.doc(widget.member!.id).update(member.toMap());
      }
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.member != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Edit Member' : 'Add Member')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
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
            DropdownButtonFormField<int>(
              initialValue: _yearOfStudy,
              decoration: const InputDecoration(labelText: 'Year of Study'),
              items: [1, 2, 3, 4, 5]
                  .map((y) => DropdownMenuItem(value: y, child: Text('Year $y')))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _yearOfStudy = v);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _courseController,
              decoration: const InputDecoration(labelText: 'Course'),
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
            const SizedBox(height: 16),
            DropdownButtonFormField<MemberStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: MemberStatus.values
                  .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date Joined'),
              subtitle: Text(DateFormat.yMMMd().format(_dateJoined)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDateJoined,
            ),
            const SizedBox(height: 16),
            Text('Tags', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _availableTags.map((tag) {
                final selected = _tags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _tags.add(tag);
                      } else {
                        _tags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Save Changes' : 'Add Member'),
            ),
          ],
        ),
      ),
    );
  }
}
