import 'package:flutter/material.dart';
import 'package:presence_manager/features/event_organization/models/event_organization.dart';

class EventOrganizationForm extends StatefulWidget {
  final EventOrganization? eventOrganization;
  final Function(EventOrganization) onSave;

  const EventOrganizationForm({
    super.key,
    this.eventOrganization,
    required this.onSave,
  });

  @override
  State<EventOrganizationForm> createState() => _EventOrganizationFormState();
}

class _EventOrganizationFormState extends State<EventOrganizationForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.eventOrganization?.description ?? '',
    );
    _locationController = TextEditingController(
      text: widget.eventOrganization?.location ?? '',
    );
    _date = widget.eventOrganization?.date ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 2,
          ),
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Localisation'),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer une localisation';
              }
              return null;
            },
          ),
          ListTile(
            title: Text(
              _date != null
                  ? 'Date: ${_date!.toLocal().toString().split(' ')[0]}'
                  : 'Sélectionner une date',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  _date = picked;
                });
              }
            },
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate() && _date != null) {
                final org = EventOrganization(
                  id:
                      widget.eventOrganization?.id ??
                      DateTime.now().millisecondsSinceEpoch.toString(),
                  eventId: widget.eventOrganization?.eventId ?? '',
                  description: _descriptionController.text,
                  date: _date!,
                  location: _locationController.text,
                );
                widget.onSave(org);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
