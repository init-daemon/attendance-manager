import 'package:flutter/material.dart';
import 'package:presence_manager/features/event/widgets/event_form.dart';
import 'package:presence_manager/features/event/models/event.dart';
import 'package:presence_manager/services/event_table_service.dart';

class EventCreateScreen extends StatefulWidget {
  const EventCreateScreen({super.key});

  @override
  State<EventCreateScreen> createState() => _EventCreateScreenState();
}

class _EventCreateScreenState extends State<EventCreateScreen> {
  void _saveEvent(Event event) async {
    await EventTableService.insert(event);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un nouvel événement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: EventForm(onSave: _saveEvent),
      ),
    );
  }
}
