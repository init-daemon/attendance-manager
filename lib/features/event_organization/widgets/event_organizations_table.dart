import 'package:flutter/material.dart';
import 'package:presence_manager/features/event_organization/models/event_organization.dart';
import 'package:presence_manager/services/date_service.dart';
import 'package:presence_manager/services/event_table_service.dart';

class EventOrganizationsTable extends StatelessWidget {
  final List<EventOrganization> organizations;
  final VoidCallback? onEdit;

  const EventOrganizationsTable({
    super.key,
    required this.organizations,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Événement')),
            DataColumn(label: Text('Date')),
            DataColumn(label: Text('Localisation')),
            DataColumn(label: Text('Description')),
            DataColumn(label: Text('Actions')),
          ],
          rows: organizations.map((org) {
            return DataRow(
              cells: [
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
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/event-organizations/edit',
                            arguments: org,
                          );
                          if (result != null && onEdit != null) onEdit!();
                        },
                      ),
                    ],
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
