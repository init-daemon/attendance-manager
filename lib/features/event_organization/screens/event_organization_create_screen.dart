import 'package:flutter/material.dart';
import 'package:presence_manager/features/event_organization/widgets/event_organization_form.dart';
import 'package:presence_manager/services/event_organization_table_service.dart';
import 'package:presence_manager/features/event_organization/models/event_organization.dart';
import 'package:presence_manager/features/event/models/event.dart';
import 'package:presence_manager/services/event_table_service.dart';
import 'package:presence_manager/features/event/widgets/event_form.dart';
import 'package:presence_manager/core/widgets/app_layout.dart';
import 'package:presence_manager/services/db_service.dart';

class EventOrganizationCreateScreen extends StatefulWidget {
  final Event? event;
  const EventOrganizationCreateScreen({super.key, this.event});

  @override
  State<EventOrganizationCreateScreen> createState() =>
      _EventOrganizationCreateScreenState();
}

class _EventOrganizationCreateScreenState
    extends State<EventOrganizationCreateScreen> {
  String? _selectedEventId;
  Event? _selectedEvent;
  bool _hasEvents = false;

  Future<String> _save(EventOrganization org) async {
    await EventOrganizationTableService.insert(org);
    return org.id;
  }

  Future<void> _selectExistingEvent() async {
    int pageSize = 10;
    int currentPage = 0;
    String searchText = '';
    List<Event> events = [];

    Future<void> loadEvents() async {
      final maps = await DbService.getPaged(
        tableName: 'events',
        limit: pageSize,
        offset: currentPage * pageSize,
        orderBy: 'name ASC',
      );
      events = maps.map((map) => Event.fromMap(map)).toList();
    }

    await loadEvents();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Choisir un événement existant'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Recherche',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) async {
                        searchText = value;
                        currentPage = 0;
                        if (searchText.trim().isEmpty) {
                          final maps = await DbService.getPaged(
                            tableName: 'events',
                            limit: pageSize,
                            offset: 0,
                            orderBy: 'name ASC',
                          );
                          setState(() {
                            events = maps
                                .map((map) => Event.fromMap(map))
                                .toList();
                          });
                        } else {
                          final maps = await DbService.search(
                            tableName: 'events',
                            query: searchText,
                            fields: ['name'],
                            limit: pageSize,
                            offset: 0,
                            orderBy: 'name ASC',
                          );
                          setState(() {
                            events = maps
                                .map((map) => Event.fromMap(map))
                                .toList();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
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
                              setState(() {});
                            },
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: currentPage > 0
                              ? () async {
                                  currentPage--;
                                  await loadEvents();
                                  setState(() {});
                                }
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: events.length == pageSize
                              ? () async {
                                  currentPage++;
                                  await loadEvents();
                                  setState(() {});
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    setState(() {});
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

  Future<void> _checkHasEvents() async {
    final count = await DbService.count('events');
    setState(() {
      _hasEvents = count > 0;
    });
  }

  @override
  void initState() {
    super.initState();
    if (widget.event != null) {
      _selectedEventId = widget.event!.id;
      _selectedEvent = widget.event;
    }
    _checkHasEvents();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Organiser un évènement',
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_selectedEventId == null) ...[
              if (_hasEvents)
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
                trailing: widget.event == null
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _selectedEventId = null;
                            _selectedEvent = null;
                          });
                        },
                      )
                    : null,
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
