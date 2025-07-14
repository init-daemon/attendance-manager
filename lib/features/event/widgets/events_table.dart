import 'package:flutter/material.dart';
import '../models/event.dart';
import '../screens/event_view_screen.dart';

class EventsTable extends StatelessWidget {
  final List<Event> events;
  final VoidCallback? onEdit;

  const EventsTable({super.key, required this.events, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Nom')),
            DataColumn(label: Text('Date de création')),
            DataColumn(label: Text('Actions')),
          ],
          rows: events.map((event) {
            return DataRow(
              cells: [
                DataCell(Text(event.name)),
                DataCell(
                  Text(
                    '${event.createdAt.day}/${event.createdAt.month}/${event.createdAt.year}',
                  ),
                ),
                DataCell(
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EventViewScreen(event: event),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/events/edit',
                            arguments: event,
                          );
                          if (result != null && result is Event) {
                            if (onEdit != null) onEdit!();
                          }
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
