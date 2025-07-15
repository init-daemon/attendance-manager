import 'package:flutter/material.dart';
import 'package:presence_manager/features/event_organization/widgets/event_organization_form.dart';
import 'package:presence_manager/services/event_organization_table_service.dart';
import 'package:presence_manager/features/event_organization/models/event_organization.dart';
import 'package:presence_manager/features/event/models/event.dart';
import 'package:presence_manager/services/event_table_service.dart';
import 'package:presence_manager/features/event/widgets/event_form.dart';

class EventOrganizationCreateScreen extends StatefulWidget {
  const EventOrganizationCreateScreen({super.key});

  @override
  State<EventOrganizationCreateScreen> createState() =>
      _EventOrganizationCreateScreenState();
}

class _EventOrganizationCreateScreenState
    extends State<EventOrganizationCreateScreen> {
  String? _selectedEventId;
  Event? _selectedEvent;

  void _save(EventOrganization org) async {
    await EventOrganizationTableService.insert(org);
    Navigator.pop(context);
  }

  Future<void> _selectExistingEvent() async {
    final events = await EventTableService.getAll();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choisir un événement existant'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return ListTile(
                  title: Text(event.name),
                  onTap: () {
                    setState(() {
                      _selectedEventId = event.id;
                      _selectedEvent = event;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> _createNewEvent() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Créer un nouvel événement'),
          content: EventForm(
            onSave: (event) async {
              await EventTableService.insert(event);
              setState(() {
                _selectedEventId = event.id;
                _selectedEvent = event;
              });
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organiser un évènement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_selectedEventId == null) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.search),
                label: const Text('Choisir un événement existant'),
                onPressed: _selectExistingEvent,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Créer un nouvel événement'),
                onPressed: _createNewEvent,
              ),
            ] else ...[
              ListTile(
                title: Text(_selectedEvent?.name ?? 'Événement sélectionné'),
                subtitle: Text('ID: $_selectedEventId'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _selectedEventId = null;
                      _selectedEvent = null;
                    });
                  },
                ),
              ),
              const Divider(),
              EventOrganizationForm(eventId: _selectedEventId!, onSave: _save),
            ],
          ],
        ),
      ),
    );
  }
}
