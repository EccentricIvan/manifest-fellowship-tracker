import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/session_model.dart';

class RecordSessionScreen extends StatefulWidget {
  const RecordSessionScreen({super.key});

  @override
  State<RecordSessionScreen> createState() => _RecordSessionScreenState();
}

class _RecordSessionScreenState extends State<RecordSessionScreen> {
  DateTime _date = DateTime.now();
  SessionType _type = SessionType.fellowship;
  int _year1 = 0;
  int _year2 = 0;
  int _year3Plus = 0;
  int _visitors = 0;
  int _newBelievers = 0;
  final _offeringController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  int get _totalAttendance => _year1 + _year2 + _year3Plus + _visitors;

  @override
  void dispose() {
    _offeringController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _save() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isSaving = true);
    try {
      final session = FellowshipSession(
        id: '',
        date: _date,
        type: _type,
        totalAttendance: _totalAttendance,
        year1Count: _year1,
        year2Count: _year2,
        year3PlusCount: _year3Plus,
        visitorsCount: _visitors,
        newBelieversCount: _newBelievers,
        offering: _offeringController.text.trim().isEmpty
            ? null
            : double.tryParse(_offeringController.text.trim()),
        notes: _notesController.text.trim(),
        recordedBy: uid,
      );
      await FirebaseFirestore.instance
          .collection('sessions')
          .add(session.toMap());
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Session')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date'),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<SessionType>(
            initialValue: _type,
            decoration: const InputDecoration(labelText: 'Session Type'),
            items: SessionType.values
                .map(
                  (t) => DropdownMenuItem(value: t, child: Text(t.name)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => _type = value);
            },
          ),
          const SizedBox(height: 16),
          _CounterRow(
            label: 'Year 1s',
            value: _year1,
            onChanged: (v) => setState(() => _year1 = v),
          ),
          _CounterRow(
            label: 'Year 2s',
            value: _year2,
            onChanged: (v) => setState(() => _year2 = v),
          ),
          _CounterRow(
            label: 'Year 3+',
            value: _year3Plus,
            onChanged: (v) => setState(() => _year3Plus = v),
          ),
          _CounterRow(
            label: 'Visitors',
            value: _visitors,
            onChanged: (v) => setState(() => _visitors = v),
          ),
          _CounterRow(
            label: 'New Believers',
            value: _newBelievers,
            onChanged: (v) => setState(() => _newBelievers = v),
          ),
          const Divider(height: 32),
          Text(
            'Total Attendance: $_totalAttendance',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _offeringController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Offering (optional)'),
          ),
          const SizedBox(height: 16),
          TextField(
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
                : const Text('Save Session'),
          ),
        ],
      ),
    );
  }
}

class _CounterRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _CounterRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
          ),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => onChanged(value + 1),
          ),
        ],
      ),
    );
  }
}
