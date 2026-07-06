import 'package:cloud_firestore/cloud_firestore.dart';

enum CallOutcome { reached, noAnswer, needsVisit, prayedWith }

CallOutcome? callOutcomeFromString(String value) {
  for (final o in CallOutcome.values) {
    if (o.name == value) return o;
  }
  return null;
}

class CallLog {
  final String id;
  final String memberId;
  final String calledBy;
  final DateTime date;
  final CallOutcome outcome;
  final String note;
  final bool followUpNeeded;

  CallLog({
    required this.id,
    required this.memberId,
    required this.calledBy,
    required this.date,
    required this.outcome,
    required this.note,
    required this.followUpNeeded,
  });

  factory CallLog.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CallLog(
      id: doc.id,
      memberId: data['memberId'] as String? ?? '',
      calledBy: data['calledBy'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      outcome: callOutcomeFromString(data['outcome'] as String? ?? '') ?? CallOutcome.noAnswer,
      note: data['note'] as String? ?? '',
      followUpNeeded: data['followUpNeeded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'calledBy': calledBy,
      'date': Timestamp.fromDate(date),
      'outcome': outcome.name,
      'note': note,
      'followUpNeeded': followUpNeeded,
    };
  }
}
