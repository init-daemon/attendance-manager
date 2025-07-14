import 'package:flutter/material.dart';
import '../widgets/event_form.dart';
import '../models/event.dart';
import '../../../services/event_table_service.dart';

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
