import 'package:flutter/material.dart';
import 'package:presence_manager/features/event_organization/models/event_organization.dart';
import 'package:presence_manager/services/date_service.dart';

class EventOrganizationForm extends StatefulWidget {
  final EventOrganization? eventOrganization;
  final String eventId;
  final Function(EventOrganization) onSave;

  const EventOrganizationForm({
    super.key,
    this.eventOrganization,
    required this.eventId,
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
    if (widget.eventId.isEmpty) {
      return const SizedBox.shrink();
    }
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
                  ? DateService.formatFr(_date!)
                  : 'Sélectionner une date',
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final pickedDate = await showDatePicker(
                context: context,
                initialDate: _date ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedDate != null) {
                final pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_date ?? DateTime.now()),
                );
                setState(() {
                  if (pickedTime != null) {
                    _date = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime.hour,
                      pickedTime.minute,
                      0,
                    );
                  } else {
                    _date = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      0,
                      0,
                      0,
                    );
                  }
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
                  eventId: widget.eventId,
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
