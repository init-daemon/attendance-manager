import 'package:flutter/material.dart';
import '../widgets/event_form.dart';
import '../models/event.dart';
import '../../../services/event_table_service.dart';

class EventEditScreen extends StatelessWidget {
  final Event event;
  static const String routeName = '/events/edit';

  const EventEditScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier un événement')),
      body: EventForm(
        event: event,
        onSave: (updated) async {
          await EventTableService.update(updated);
          Navigator.pop(context, updated);
        },
      ),
    );
  }
}
