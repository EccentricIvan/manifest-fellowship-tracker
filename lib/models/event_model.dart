import 'package:cloud_firestore/cloud_firestore.dart';

enum FellowshipEventType { jieu, conference, outreach }

FellowshipEventType? eventTypeFromString(String value) {
  switch (value) {
    case 'JIEU':
      return FellowshipEventType.jieu;
    case 'conference':
      return FellowshipEventType.conference;
    case 'outreach':
      return FellowshipEventType.outreach;
    default:
      return null;
  }
}

String eventTypeToString(FellowshipEventType type) {
  switch (type) {
    case FellowshipEventType.jieu:
      return 'JIEU';
    case FellowshipEventType.conference:
      return 'conference';
    case FellowshipEventType.outreach:
      return 'outreach';
  }
}

class FellowshipEvent {
  final String id;
  final String name;
  final DateTime date;
  final FellowshipEventType type;
  final int mobilisedCount;
  final int attendedCount;
  final double transportCost;
  final String notes;

  FellowshipEvent({
    required this.id,
    required this.name,
    required this.date,
    required this.type,
    required this.mobilisedCount,
    required this.attendedCount,
    required this.transportCost,
    required this.notes,
  });

  factory FellowshipEvent.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FellowshipEvent(
      id: doc.id,
      name: data['name'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      type: eventTypeFromString(data['type'] as String? ?? '') ?? FellowshipEventType.outreach,
      mobilisedCount: data['mobilisedCount'] as int? ?? 0,
      attendedCount: data['attendedCount'] as int? ?? 0,
      transportCost: (data['transportCost'] as num?)?.toDouble() ?? 0,
      notes: data['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'date': Timestamp.fromDate(date),
      'type': eventTypeToString(type),
      'mobilisedCount': mobilisedCount,
      'attendedCount': attendedCount,
      'transportCost': transportCost,
      'notes': notes,
    };
  }
}
