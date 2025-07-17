import 'package:flutter/material.dart';
import 'package:presence_manager/features/event_organization/models/event_organization.dart';
import 'package:presence_manager/services/event_table_service.dart';
import 'package:presence_manager/services/date_service.dart';
import 'package:presence_manager/core/widgets/app_layout.dart';

class EventOrganizationViewScreen extends StatelessWidget {
  final EventOrganization eventOrganization;

  const EventOrganizationViewScreen({
    super.key,
    required this.eventOrganization,
  });

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Détails organisation',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder(
                  future: EventTableService.getById(eventOrganization.eventId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      );
                    }
                    if (snapshot.hasData && snapshot.data != null) {
                      return _buildInfoRow('Événement', snapshot.data!.name);
                    }
                    return _buildInfoRow('Événement', 'Non trouvé');
                  },
                ),
                _buildInfoRow(
                  'Date',
                  DateService.formatFrLong(eventOrganization.date),
                ),
                _buildInfoRow('Localisation', eventOrganization.location),
                _buildInfoRow(
                  'Description',
                  eventOrganization.description ?? '',
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
