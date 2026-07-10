import 'package:cloud_firestore/cloud_firestore.dart';

enum Campus { victoria, makerere }

enum MemberStatus { active, inactive, alumni }

Campus? campusFromString(String value) {
  for (final c in Campus.values) {
    if (c.name == value) return c;
  }
  return null;
}

MemberStatus? memberStatusFromString(String value) {
  for (final s in MemberStatus.values) {
    if (s.name == value) return s;
  }
  return null;
}

class Member {
  final String id;
  final String name;
  final String phone;
  final String gender;
  final int yearOfStudy;
  final String course;
  final Campus campus;
  final DateTime dateJoined;
  final MemberStatus status;
  final List<String> tags;
  final String residence;
  final bool wantsToServe;
  final bool wantsTransport;

  Member({
    required this.id,
    required this.name,
    required this.phone,
    required this.gender,
    required this.yearOfStudy,
    required this.course,
    required this.campus,
    required this.dateJoined,
    required this.status,
    required this.tags,
    this.residence = '',
    this.wantsToServe = false,
    this.wantsTransport = false,
  });

  factory Member.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Member(
      id: doc.id,
      name: data['name'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      gender: data['gender'] as String? ?? '',
      yearOfStudy: data['yearOfStudy'] as int? ?? 1,
      course: data['course'] as String? ?? '',
      campus: campusFromString(data['campus'] as String? ?? '') ?? Campus.victoria,
      dateJoined: (data['dateJoined'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: memberStatusFromString(data['status'] as String? ?? '') ?? MemberStatus.active,
      tags: List<String>.from(data['tags'] as List? ?? const []),
      residence: data['residence'] as String? ?? '',
      wantsToServe: data['wantsToServe'] as bool? ?? false,
      wantsTransport: data['wantsTransport'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'gender': gender,
      'yearOfStudy': yearOfStudy,
      'course': course,
      'campus': campus.name,
      'dateJoined': Timestamp.fromDate(dateJoined),
      'status': status.name,
      'tags': tags,
      'residence': residence,
      'wantsToServe': wantsToServe,
      'wantsTransport': wantsTransport,
    };
  }
}
