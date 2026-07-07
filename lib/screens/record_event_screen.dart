import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/event_model.dart';

class RecordEventScreen extends StatefulWidget {
  const RecordEventScreen({super.key});

  @override
  State<RecordEventScreen> createState() => _RecordEventScreenState();
}

class _RecordEventScreenState extends State<RecordEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobilisedController = TextEditingController(text: '0');
  final _attendedController = TextEditingController(text: '0');
  final _costController = TextEditingController(text: '0');
  final _notesController = TextEditingController();
  DateTime _date = DateTime.now();
  FellowshipEventType _type = FellowshipEventType.outreach;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobilisedController.dispose();
    _attendedController.dispose();
    _costController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final event = FellowshipEvent(
        id: '',
        name: _nameController.text.trim(),
        date: _date,
        type: _type,
        mobilisedCount: int.tryParse(_mobilisedController.text.trim()) ?? 0,
        attendedCount: int.tryParse(_attendedController.text.trim()) ?? 0,
        transportCost: double.tryParse(_costController.text.trim()) ?? 0,
        notes: _notesController.text.trim(),
      );
      await FirebaseFirestore.instance.collection('events').add(event.toMap());
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Event')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Event Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter an event name' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMd().format(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<FellowshipEventType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Event Type'),
              items: const [
                DropdownMenuItem(
                  value: FellowshipEventType.jieu,
                  child: Text('JIEU'),
                ),
                DropdownMenuItem(
                  value: FellowshipEventType.conference,
                  child: Text('Conference'),
                ),
                DropdownMenuItem(
                  value: FellowshipEventType.outreach,
                  child: Text('Outreach'),
                ),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _type = value);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mobilisedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Mobilised Count'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _attendedController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Attended Count'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _costController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Transport Cost'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notes'),
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
                  : const Text('Save Event'),
            ),
          ],
        ),
      ),
    );
  }
}
