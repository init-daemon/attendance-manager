import 'package:flutter/material.dart';
import 'package:attendance_app/features/event/models/event.dart';

class EventForm extends StatefulWidget {
  final Event? event;
  final Function(Event) onSave;

  const EventForm({super.key, this.event, required this.onSave});

  @override
  State<EventForm> createState() => _EventFormState();
}

class _EventFormState extends State<EventForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.event?.name ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nom de l\'événement'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un nom';
              }
              return null;
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text('Annuler'),
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/events',
                    (route) => false,
                  );
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final event = Event(
                      id:
                          widget.event?.id ??
                          DateTime.now().millisecondsSinceEpoch.toString(),
                      name: _nameController.text,
                      createdAt: widget.event?.createdAt ?? DateTime.now(),
                    );
                    widget.onSave(event);
                  }
                },
                child: const Text('Enregistrer'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
