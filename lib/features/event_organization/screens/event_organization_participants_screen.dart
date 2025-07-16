import 'package:flutter/material.dart';
import 'package:presence_manager/features/event_organization/widgets/event_participants_table.dart';
import 'package:presence_manager/services/event_organization_table_service.dart';

class EventOrganizationParticipantsScreen extends StatelessWidget {
  final String eventOrganizationId;

  const EventOrganizationParticipantsScreen({
    super.key,
    required this.eventOrganizationId,
  });

  @override
  Widget build(BuildContext context) {
    if (eventOrganizationId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Participants')),
        body: const Center(child: Text('Aucun événement sélectionné')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Participants'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            final eventOrg = await EventOrganizationTableService.getAll().then(
              (list) => list.firstWhere((e) => e.id == eventOrganizationId),
            );
            Navigator.pushReplacementNamed(
              context,
              '/event-organizations/edit',
              arguments: eventOrg,
            );
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: EventParticipantsTable(eventOrganizationId: eventOrganizationId),
      ),
    );
  }
}
