import 'package:flutter/material.dart';
import 'package:presence_manager/features/event/models/event.dart';
import 'package:presence_manager/core/widgets/app_layout.dart';
import 'package:presence_manager/features/event/screens/event_edit_screen.dart';
import 'package:presence_manager/features/event_organization/models/event_organization.dart';
import 'package:presence_manager/features/event_organization/widgets/event_organizations_table.dart';
import 'package:presence_manager/services/db_service.dart';
import 'package:presence_manager/shared/constants/pagination_constants.dart';

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

  @override
  void initState() {
    super.initState();
    _loadOrgs();
  }

  void _loadOrgs() {
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

  int get totalPages => (_totalOrgs / _pageSize).ceil();

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Détails de l\'événement',
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
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
                          const SizedBox(width: 12),
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
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Text('Événements organisés associés :'),
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
              ),
              FutureBuilder<List<EventOrganization>>(
                future: _orgsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Erreur: ${snapshot.error}'));
                  } else {
                    final orgs = snapshot.data ?? [];
                    return EventOrganizationsTable(
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
