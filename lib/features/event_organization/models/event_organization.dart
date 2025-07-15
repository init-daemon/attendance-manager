import 'package:presence_manager/features/event/models/event.dart';
import 'package:presence_manager/services/event_table_service.dart';

class EventOrganization {
  final String id;
  final String eventId;
  final String? description;
  final DateTime date;
  final String location;

  EventOrganization({
    required this.id,
    required this.eventId,
    this.description,
    required this.date,
    required this.location,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'event_id': eventId,
      'description': description,
      'date': date.toIso8601String(),
      'location': location,
    };
  }

  factory EventOrganization.fromMap(Map<String, dynamic> map) {
    return EventOrganization(
      id: map['id'] ?? '',
      eventId: map['event_id'] ?? '',
      description: map['description'],
      date: DateTime.parse(map['date']),
      location: map['location'] ?? '',
    );
  }

  Future<Event?> fetchEvent() async {
    return await EventTableService.getById(eventId);
  }
}
