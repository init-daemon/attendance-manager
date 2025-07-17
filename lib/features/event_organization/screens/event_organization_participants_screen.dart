import 'package:flutter/material.dart';
import 'package:presence_manager/features/event_organization/widgets/event_participants_table.dart';
import 'package:presence_manager/features/event_organization/models/event_organization.dart';
import 'package:presence_manager/services/event_table_service.dart';
import 'package:presence_manager/services/date_service.dart';

class EventOrganizationParticipantsScreen extends StatelessWidget {
  final String eventOrganizationId;
  final EventOrganization? eventOrganization;

  const EventOrganizationParticipantsScreen({
    super.key,
    required this.eventOrganizationId,
    this.eventOrganization,
  });

  @override
  Widget build(BuildContext context) {
    if (eventOrganizationId.isEmpty || eventOrganization == null) {
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
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder(
                        future: EventTableService.getById(
                          eventOrganization!.eventId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(),
                            );
                          }
                          if (snapshot.hasData && snapshot.data != null) {
                            return _buildInfoRow(
                              'Événement',
                              snapshot.data!.name,
                            );
                          }
                          return _buildInfoRow('Événement', 'Non trouvé');
                        },
                      ),
                      _buildInfoRow(
                        'Date',
                        DateService.formatFrLong(eventOrganization!.date),
                      ),
                      _buildInfoRow(
                        'Localisation',
                        eventOrganization!.location,
                      ),
                      _buildInfoRow(
                        'Description',
                        eventOrganization!.description ?? '',
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Modifier'),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/event-organizations/edit',
                                arguments: eventOrganization,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.list),
                            label: const Text('Liste'),
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/event-organizations',
                                (route) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child: EventParticipantsTable(
                  eventOrganizationId: eventOrganizationId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
