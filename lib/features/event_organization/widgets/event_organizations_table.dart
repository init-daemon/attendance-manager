import 'package:flutter/material.dart';
import 'package:attendance_app/features/event_organization/models/event_organization.dart';
import 'package:attendance_app/services/date_service.dart';
import 'package:attendance_app/services/event_table_service.dart';
import 'package:attendance_app/services/event_participant_table_service.dart';

class EventOrganizationsTable extends StatelessWidget {
  final List<EventOrganization> organizations;
  final VoidCallback? onEdit;
  final Function(EventOrganization)? onManageParticipants;
  final Function(EventOrganization)? onEditOrganization;
  final Function(EventOrganization)? onDeleteOrganization;

  const EventOrganizationsTable({
    super.key,
    required this.organizations,
    this.onEdit,
    this.onManageParticipants,
    this.onEditOrganization,
    this.onDeleteOrganization,
  });

  @override
  Widget build(BuildContext context) {
    if (organizations.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text('Aucun évènement organisé associé')),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Actions')),
            DataColumn(label: Text('Événement')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Localisation')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Participants')),
          ],
          rows: organizations.map((org) {
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          Navigator.pushNamed(
                            context,
                            '/event-organizations/view',
                            arguments: org,
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          if (onEditOrganization != null) {
                            onEditOrganization!(org);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.group),
                        onPressed: () {
                          if (onManageParticipants != null) {
                            onManageParticipants!(org);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        color: Theme.of(context).colorScheme.error,
                        onPressed: () {
                          if (onDeleteOrganization != null) {
                            onDeleteOrganization!(org);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                DataCell(
                  FutureBuilder(
                    future: EventTableService.getById(org.eventId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          width: 80,
                          height: 16,
                          child: LinearProgressIndicator(),
                        );
                      }
                      if (snapshot.hasData && snapshot.data != null) {
                        return Text(snapshot.data!.name);
                      }
                      return const Text('Non trouvé');
                    },
                  ),
                ),
                DataCell(Text(DateService.formatFr(org.date))),
                DataCell(Text(org.location)),
                DataCell(Text(org.description ?? '')),
                DataCell(
                  FutureBuilder(
                    future:
                        EventParticipantTableService.getByEventOrganizationId(
                          org.id,
                          includeHidden: false,
                        ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          width: 40,
                          height: 16,
                          child: LinearProgressIndicator(),
                        );
                      }
                      if (snapshot.hasData) {
                        final participants = snapshot.data as List;
                        return Text('${participants.length}');
                      }
                      return const Text('0');
                    },
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
