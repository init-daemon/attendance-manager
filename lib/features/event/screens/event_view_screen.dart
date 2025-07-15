import 'package:flutter/material.dart';
import 'package:presence_manager/features/event/models/event.dart';
import 'package:presence_manager/core/widgets/app_layout.dart';
import 'package:presence_manager/features/event/screens/event_edit_screen.dart';

class EventViewScreen extends StatelessWidget {
  final Event event;
  static const String routeName = '/events/view';

  const EventViewScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Détails de l\'événement',
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            Navigator.pushNamed(
              context,
              EventEditScreen.routeName,
              arguments: event,
            ).then((updatedEvent) {
              if (updatedEvent != null && updatedEvent is Event) {
                Navigator.pop(context, updatedEvent);
              }
            });
          },
        ),
      ],
      body: SingleChildScrollView(
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Nom', event.name),
                  _buildInfoRow(
                    'Date de création',
                    '${event.createdAt.day}/${event.createdAt.month}/${event.createdAt.year}',
                  ),
                ],
              ),
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
