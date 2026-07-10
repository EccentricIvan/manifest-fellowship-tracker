import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/member_model.dart';
import 'first_timer_quick_add_screen.dart';
import 'member_form_screen.dart';

class MembersRegisterScreen extends StatefulWidget {
  const MembersRegisterScreen({super.key});

  @override
  State<MembersRegisterScreen> createState() => _MembersRegisterScreenState();
}

class _MembersRegisterScreenState extends State<MembersRegisterScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members Register'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search by name or phone',
                prefixIcon: Icon(Icons.search),
                filled: true,
              ),
              onChanged: (value) =>
                  setState(() => _query = value.trim().toLowerCase()),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bolt),
            tooltip: 'First-timer quick add',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FirstTimerQuickAddScreen(),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('members').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final members = (snapshot.data?.docs ?? [])
              .map(Member.fromDoc)
              .where((m) {
                if (_query.isEmpty) return true;
                return m.name.toLowerCase().contains(_query) ||
                    m.phone.toLowerCase().contains(_query);
              })
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          if (members.isEmpty) {
            return const Center(child: Text('No members found.'));
          }

          return ListView.separated(
            itemCount: members.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = members[index];
              final locationParts = [
                member.campus == Campus.victoria ? 'Victoria' : 'Makerere',
                if (member.residence.isNotEmpty) member.residence,
              ];
              return ListTile(
                title: Text(member.name),
                subtitle: Text(
                  '${member.phone} · ${locationParts.join(', ')} · Year ${member.yearOfStudy}',
                ),
                trailing: Wrap(
                  spacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (member.wantsToServe)
                      const Tooltip(message: 'Wants to serve', child: Icon(Icons.volunteer_activism, size: 18)),
                    if (member.wantsTransport)
                      const Tooltip(message: 'Wants transport', child: Icon(Icons.directions_bus, size: 18)),
                    ...member.tags.map(
                      (t) => Chip(label: Text(t), visualDensity: VisualDensity.compact),
                    ),
                  ],
                ),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MemberFormScreen(member: member),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MemberFormScreen()),
        ),
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
