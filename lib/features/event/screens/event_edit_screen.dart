import 'package:flutter/material.dart';
import 'package:attendance_app/features/event/widgets/event_form.dart';
import 'package:attendance_app/features/event/models/event.dart';
import 'package:attendance_app/services/event_table_service.dart';

class EventEditScreen extends StatelessWidget {
  final Event event;
  static const String routeName = '/events/edit';

  const EventEditScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier un événement')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: EventForm(
          event: event,
          onSave: (updated) async {
            await EventTableService.update(updated);
            Navigator.pop(context, updated);
          },
        ),
      ),
    );
  }
}
