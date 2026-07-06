import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionType { fellowship, prayer, outreach }

SessionType? sessionTypeFromString(String value) {
  for (final t in SessionType.values) {
    if (t.name == value) return t;
  }
  return null;
}

class FellowshipSession {
  final String id;
  final DateTime date;
  final SessionType type;
  final int totalAttendance;
  final int year1Count;
  final int year2Count;
  final int year3PlusCount;
  final int visitorsCount;
  final int newBelieversCount;
  final double? offering;
  final String notes;
  final String recordedBy;

  FellowshipSession({
    required this.id,
    required this.date,
    required this.type,
    required this.totalAttendance,
    required this.year1Count,
    required this.year2Count,
    required this.year3PlusCount,
    required this.visitorsCount,
    required this.newBelieversCount,
    this.offering,
    required this.notes,
    required this.recordedBy,
  });

  factory FellowshipSession.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FellowshipSession(
      id: doc.id,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: sessionTypeFromString(data['type'] as String? ?? '') ?? SessionType.fellowship,
      totalAttendance: data['totalAttendance'] as int? ?? 0,
      year1Count: data['year1Count'] as int? ?? 0,
      year2Count: data['year2Count'] as int? ?? 0,
      year3PlusCount: data['year3PlusCount'] as int? ?? 0,
      visitorsCount: data['visitorsCount'] as int? ?? 0,
      newBelieversCount: data['newBelieversCount'] as int? ?? 0,
      offering: (data['offering'] as num?)?.toDouble(),
      notes: data['notes'] as String? ?? '',
      recordedBy: data['recordedBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'type': type.name,
      'totalAttendance': totalAttendance,
      'year1Count': year1Count,
      'year2Count': year2Count,
      'year3PlusCount': year3PlusCount,
      'visitorsCount': visitorsCount,
      'newBelieversCount': newBelieversCount,
      if (offering != null) 'offering': offering,
      'notes': notes,
      'recordedBy': recordedBy,
    };
  }
}
