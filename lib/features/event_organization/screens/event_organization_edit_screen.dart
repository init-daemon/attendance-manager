import 'package:flutter/material.dart';
import 'package:presence_manager/features/event_organization/widgets/event_organization_form.dart';
import 'package:presence_manager/services/event_organization_table_service.dart';
import 'package:presence_manager/features/event_organization/models/event_organization.dart';

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
      appBar: AppBar(title: const Text('Modifier organisation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: EventOrganizationForm(
          eventOrganization: eventOrganization,
          onSave: (org) => _save(context, org),
        ),
      ),
    );
  }
}
