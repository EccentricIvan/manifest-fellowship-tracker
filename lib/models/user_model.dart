import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, leader, usher, callCentre, transport }

UserRole? userRoleFromString(String value) {
  for (final role in UserRole.values) {
    if (role.name == value) return role;
  }
  return null;
}

class AppUser {
  final String uid;
  final String name;
  final String phone;
  final UserRole role;
  final String? linkedMemberId;

  AppUser({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    this.linkedMemberId,
  });

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return AppUser(
      uid: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: userRoleFromString(data['role'] as String? ?? '') ?? UserRole.usher,
      linkedMemberId: data['linkedMemberId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'role': role.name,
      'linkedMemberId': linkedMemberId,
    };
  }

  @override
  bool operator ==(Object other) => other is AppUser && other.uid == uid;

  @override
  int get hashCode => uid.hashCode;
}
