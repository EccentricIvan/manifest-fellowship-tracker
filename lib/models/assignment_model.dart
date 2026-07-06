import 'package:cloud_firestore/cloud_firestore.dart';

enum AssignmentReason { firstTimer, absent, pastoral }

enum AssignmentStatus { pending, done }

AssignmentReason? assignmentReasonFromString(String value) {
  for (final r in AssignmentReason.values) {
    if (r.name == value) return r;
  }
  return null;
}

AssignmentStatus? assignmentStatusFromString(String value) {
  for (final s in AssignmentStatus.values) {
    if (s.name == value) return s;
  }
  return null;
}

class Assignment {
  final String id;
  final String memberId;
  final String assignedTo;
  final AssignmentReason reason;
  final AssignmentStatus status;
  final DateTime dueDate;

  Assignment({
    required this.id,
    required this.memberId,
    required this.assignedTo,
    required this.reason,
    required this.status,
    required this.dueDate,
  });

  factory Assignment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Assignment(
      id: doc.id,
      memberId: data['memberId'] as String? ?? '',
      assignedTo: data['assignedTo'] as String? ?? '',
      reason: assignmentReasonFromString(data['reason'] as String? ?? '') ?? AssignmentReason.pastoral,
      status: assignmentStatusFromString(data['status'] as String? ?? '') ?? AssignmentStatus.pending,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'assignedTo': assignedTo,
      'reason': reason.name,
      'status': status.name,
      'dueDate': Timestamp.fromDate(dueDate),
    };
  }
}
