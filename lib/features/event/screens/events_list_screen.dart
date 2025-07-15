import 'package:flutter/material.dart';
import 'package:presence_manager/services/event_table_service.dart';
import '../widgets/events_table.dart';
import '../models/event.dart';
import 'event_create_screen.dart';
import 'package:presence_manager/core/widgets/app_layout.dart';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  late Future<List<Event>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = EventTableService.getAll();
  }

  void _refreshEvents() {
    setState(() {
      _eventsFuture = EventTableService.getAll();
    });
  }

  void _navigateToCreateScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EventCreateScreen()),
    );
    _refreshEvents();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Liste des Événements',
      body: FutureBuilder<List<Event>>(
        future: _eventsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            return Column(
              children: [
                Expanded(
                  child: EventsTable(
                    events: snapshot.data!,
                    onEdit: _refreshEvents,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FloatingActionButton.extended(
                    onPressed: () => _navigateToCreateScreen(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Créer un événement'),
                  ),
                ),
              ],
            );
          }
        },
      ),
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _navigateToCreateScreen(context),
        ),
      ],
    );
  }
}
