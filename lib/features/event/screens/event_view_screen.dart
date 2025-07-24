import 'package:flutter/material.dart';
import 'package:attendance_app/features/event/models/event.dart';
import 'package:attendance_app/core/widgets/app_layout.dart';
import 'package:attendance_app/features/event/screens/event_edit_screen.dart';
import 'package:attendance_app/features/event_organization/models/event_organization.dart';
import 'package:attendance_app/features/event_organization/widgets/event_organizations_table.dart';
import 'package:attendance_app/services/db_service.dart';
import 'package:attendance_app/services/event_participant_table_service.dart';
import 'package:attendance_app/shared/constants/pagination_constants.dart';
import 'dart:async';

class EventViewScreen extends StatefulWidget {
  final Event event;
  static const String routeName = '/events/view';

  const EventViewScreen({super.key, required this.event});

  @override
  State<EventViewScreen> createState() => _EventViewScreenState();
}

class _EventViewScreenState extends State<EventViewScreen> {
  int _currentPage = 0;
  int _pageSize = PaginationConstants.defaultPageSize;
  int _totalOrgs = 0;
  late Future<List<EventOrganization>> _orgsFuture;
  String _searchText = '';
  Timer? _debounce;

  int presentCount = 0;
  int absentCount = 0;
  bool statsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrgs();
    _loadParticipationStats();
  }

  void _loadOrgs() {
    if (_searchText.isEmpty) {
      setState(() {
        _orgsFuture =
            DbService.getPaged(
              tableName: 'event_organizations',
              limit: _pageSize,
              offset: _currentPage * _pageSize,
              orderBy: 'date DESC',
            ).then(
              (maps) => maps
                  .map((map) => EventOrganization.fromMap(map))
                  .where((org) => org.eventId == widget.event.id)
                  .toList(),
            );
        DbService.count('event_organizations').then((count) {
          setState(() {
            _totalOrgs = count;
          });
        });
      });
    } else {
      setState(() {
        _orgsFuture =
            DbService.search(
              tableName: 'event_organizations',
              query: _searchText,
              fields: ['location', 'description'],
              limit: _pageSize,
              offset: _currentPage * _pageSize,
              orderBy: 'date DESC',
            ).then(
              (maps) => maps
                  .map((map) => EventOrganization.fromMap(map))
                  .where((org) => org.eventId == widget.event.id)
                  .toList(),
            );
        DbService.search(
          tableName: 'event_organizations',
          query: _searchText,
          fields: ['location', 'description'],
          limit: 1000000,
          offset: 0,
        ).then((maps) {
          setState(() {
            _totalOrgs = maps
                .map((map) => EventOrganization.fromMap(map))
                .where((org) => org.eventId == widget.event.id)
                .length;
          });
        });
      });
    }
  }

  Future<void> _loadParticipationStats() async {
    setState(() => statsLoading = true);
    final orgMaps = await DbService.getByField(
      tableName: 'event_organizations',
      field: 'event_id',
      value: widget.event.id,
    );
    int present = 0;
    int absent = 0;
    for (final orgMap in orgMaps) {
      final orgId = orgMap['id'] as String;
      final participants =
          await EventParticipantTableService.getByEventOrganizationId(orgId);
      for (final p in participants) {
        if (p.isPresent) {
          present++;
        } else {
          absent++;
        }
      }
    }
    setState(() {
      presentCount = present;
      absentCount = absent;
      statsLoading = false;
    });
  }

  void _onPageSizeChanged(int? value) {
    if (value != null) {
      setState(() {
        _pageSize = value;
        _currentPage = 0;
      });
      _loadOrgs();
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadOrgs();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _searchText = value;
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _currentPage = 0;
      _loadOrgs();
    });
  }

  int get totalPages => (_totalOrgs / _pageSize).ceil();

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Détails du type d\'événement',
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            Navigator.pushNamed(
              context,
              EventEditScreen.routeName,
              arguments: widget.event,
            ).then((updatedEvent) {
              if (updatedEvent != null && updatedEvent is Event) {
                Navigator.pop(context, updatedEvent);
              }
            });
          },
        ),
      ],
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Nom', widget.event.name),
                      _buildInfoRow(
                        'Date de création',
                        '${widget.event.createdAt.day}/${widget.event.createdAt.month}/${widget.event.createdAt.year}',
                      ),
                      const SizedBox(height: 24),
                      statsLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSecondary,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Présent : $presentCount',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.cancel,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onError,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Absent : $absentCount',
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onError,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceBetween,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.event),
                            label: const Text('Organiser un évènement'),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/event-organizations/create',
                                arguments: widget.event,
                              );
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Modifier'),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                EventEditScreen.routeName,
                                arguments: widget.event,
                              ).then((updatedEvent) {
                                if (updatedEvent != null &&
                                    updatedEvent is Event) {
                                  Navigator.pop(context, updatedEvent);
                                }
                              });
                            },
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.list),
                            label: const Text('Liste'),
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/events',
                                (route) => false,
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FutureBuilder<List<EventOrganization>>(
                future: _orgsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  } else {
                    final orgs = snapshot.data ?? [];
                    if (orgs.isEmpty) {
                      return Column(
                        children: [
                          const Text(
                            'Aucun événement organisé associé.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Organiser un évènement'),
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/event-organizations/create',
                                arguments: widget.event,
                              );
                            },
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Column(
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  labelText:
                                      'Recherche (localisation ou description)',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: _onSearchChanged,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Text('Événements associés :'),
                                  const Spacer(),
                                  DropdownButton<int>(
                                    value: _pageSize,
                                    items: PaginationConstants.pageSizes
                                        .map(
                                          (size) => DropdownMenuItem(
                                            value: size,
                                            child: Text('$size'),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: _onPageSizeChanged,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: _currentPage > 0
                                        ? () => _onPageChanged(_currentPage - 1)
                                        : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: _currentPage < totalPages - 1
                                        ? () => _onPageChanged(_currentPage + 1)
                                        : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        EventOrganizationsTable(
                          organizations: orgs,
                          onEdit: _loadOrgs,
                          onManageParticipants: (org) {
                            Navigator.pushNamed(
                              context,
                              '/event-organization/participants',
                              arguments: {
                                'eventOrganizationId': org.id,
                                'eventOrganization': org,
                              },
                            );
                          },
                          onEditOrganization: (org) {
                            Navigator.pushNamed(
                              context,
                              '/event-organizations/edit',
                              arguments: org,
                            );
                          },
                        ),
                      ],
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }
}
