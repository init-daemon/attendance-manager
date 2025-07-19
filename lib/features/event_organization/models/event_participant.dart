class EventParticipant {
  final String eventOrganizationId;
  final String individualId;
  bool isPresent;
  bool isHidden;

  EventParticipant({
    required this.eventOrganizationId,
    required this.individualId,
    this.isPresent = false,
    this.isHidden = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'event_organization_id': eventOrganizationId,
      'individual_id': individualId,
      'is_present': isPresent ? 1 : 0,
    };
  }

  factory EventParticipant.fromMap(Map<String, dynamic> map) {
    return EventParticipant(
      eventOrganizationId: map['event_organization_id'],
      individualId: map['individual_id'],
      isPresent: map['is_present'] == 1,
      isHidden: map['isHidden'] == 1,
    );
  }
}
