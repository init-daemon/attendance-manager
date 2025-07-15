import 'package:flutter/material.dart';
import 'package:presence_manager/features/event_organization/models/event_organization.dart';

class EventOrganizationViewScreen extends StatelessWidget {
  final EventOrganization eventOrganization;

  const EventOrganizationViewScreen({
    super.key,
    required this.eventOrganization,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Détails organisation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  'Date',
                  '${eventOrganization.date.day}/${eventOrganization.date.month}/${eventOrganization.date.year}',
                ),
                _buildInfoRow('Localisation', eventOrganization.location),
                _buildInfoRow(
                  'Description',
                  eventOrganization.description ?? '',
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
