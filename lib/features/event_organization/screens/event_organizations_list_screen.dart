import 'package:flutter/material.dart';
import 'package:presence_manager/features/event_organization/widgets/event_organizations_table.dart';
import 'package:presence_manager/services/event_organization_table_service.dart';
import 'package:presence_manager/features/event_organization/models/event_organization.dart';

class EventOrganizationsListScreen extends StatefulWidget {
  const EventOrganizationsListScreen({super.key});

  @override
  State<EventOrganizationsListScreen> createState() =>
      _EventOrganizationsListScreenState();
}

class _EventOrganizationsListScreenState
    extends State<EventOrganizationsListScreen> {
  late Future<List<EventOrganization>> _orgsFuture;

  @override
  void initState() {
    super.initState();
    _orgsFuture = EventOrganizationTableService.getAll();
  }

  void _refresh() {
    setState(() {
      _orgsFuture = EventOrganizationTableService.getAll();
    });
  }

  void _navigateToCreate(BuildContext context) async {
    await Navigator.pushNamed(context, '/event-organizations/create');
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organisations d\'événement')),
      body: FutureBuilder<List<EventOrganization>>(
        future: _orgsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            return Column(
              children: [
                Expanded(
                  child: EventOrganizationsTable(
                    organizations: snapshot.data!,
                    onEdit: _refresh,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton.extended(
                        onPressed: () => _navigateToCreate(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Nouvelle organisation'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
