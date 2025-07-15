import 'package:flutter/material.dart';
import 'package:presence_manager/features/event_organization/widgets/event_organization_form.dart';
import 'package:presence_manager/services/event_organization_table_service.dart';
import 'package:presence_manager/features/event_organization/models/event_organization.dart';

class EventOrganizationCreateScreen extends StatelessWidget {
  const EventOrganizationCreateScreen({super.key});

  void _save(BuildContext context, EventOrganization org) async {
    await EventOrganizationTableService.insert(org);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nouvelle organisation')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: EventOrganizationForm(onSave: (org) => _save(context, org)),
      ),
    );
  }
}
