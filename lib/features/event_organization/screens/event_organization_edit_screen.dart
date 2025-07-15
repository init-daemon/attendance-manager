import 'package:flutter/material.dart';
import 'package:presence_manager/features/event_organization/widgets/event_organization_form.dart';
import 'package:presence_manager/services/event_organization_table_service.dart';
import 'package:presence_manager/features/event_organization/models/event_organization.dart';
import 'package:presence_manager/services/event_table_service.dart';

class EventOrganizationEditScreen extends StatelessWidget {
  final EventOrganization eventOrganization;

  const EventOrganizationEditScreen({
    super.key,
    required this.eventOrganization,
  });

  void _save(BuildContext context, EventOrganization org) async {
    await EventOrganizationTableService.update(org);
    Navigator.pop(context, org);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier l\'événement organisé')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
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
                  return ListTile(
                    title: RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: [
                          const TextSpan(text: 'Évènement associé : '),
                          TextSpan(
                            text: snapshot.data!.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const ListTile(
                  title: Text('Évènement associé non trouvé'),
                );
              },
            ),
            const Divider(),
            EventOrganizationForm(
              eventOrganization: eventOrganization,
              eventId: eventOrganization.eventId,
              onSave: (org) => _save(context, org),
            ),
          ],
        ),
      ),
    );
  }
}
