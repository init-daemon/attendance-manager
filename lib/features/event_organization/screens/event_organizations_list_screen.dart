import 'package:flutter/material.dart';
import 'package:attendance_app/features/event_organization/widgets/event_organizations_table.dart';
import 'package:attendance_app/features/event_organization/models/event_organization.dart';
import 'package:attendance_app/core/widgets/app_layout.dart';
import 'package:attendance_app/shared/constants/pagination_constants.dart';
import 'package:attendance_app/services/db_service.dart';
import 'dart:async';

class EventOrganizationsListScreen extends StatefulWidget {
  const EventOrganizationsListScreen({super.key});

  @override
  State<EventOrganizationsListScreen> createState() =>
      _EventOrganizationsListScreenState();
}

class _EventOrganizationsListScreenState
    extends State<EventOrganizationsListScreen> {
  int _currentPage = 0;
  int _pageSize = PaginationConstants.defaultPageSize;
  int _totalOrgs = 0;
  late Future<List<EventOrganization>> _orgsFuture;
  String _searchText = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadOrgs();
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
              (maps) =>
                  maps.map((map) => EventOrganization.fromMap(map)).toList(),
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
              (maps) =>
                  maps.map((map) => EventOrganization.fromMap(map)).toList(),
            );
        DbService.search(
          tableName: 'event_organizations',
          query: _searchText,
          fields: ['location', 'description'],
          limit: 1000000,
          offset: 0,
        ).then((maps) {
          setState(() {
            _totalOrgs = maps.length;
          });
        });
      });
    }
  }

  void _refresh() {
    _loadOrgs();
  }

  void _navigateToCreate(BuildContext context) async {
    await Navigator.pushNamed(context, '/event-organizations/create');
    _refresh();
  }

  void _navigateToParticipants(
    BuildContext context,
    EventOrganization org,
  ) async {
    await Navigator.pushNamed(
      context,
      '/event-organization/participants',
      arguments: {'eventOrganizationId': org.id, 'eventOrganization': org},
    );
    _refresh();
  }

  void _navigateToEdit(BuildContext context, EventOrganization org) async {
    await Navigator.pushNamed(
      context,
      '/event-organizations/edit',
      arguments: org,
    );
    _refresh();
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

  Future<void> _deleteOrganization(
    BuildContext context,
    EventOrganization org,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          "Supprimer cet événement supprimera aussi les données associées. Voulez-vous vraiment continuer ?",
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.delete),
            label: const Text('Supprimer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final db = await DbService.getDatabase();
      await db.delete(
        'event_organizations',
        where: 'id = ?',
        whereArgs: [org.id],
      );
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Organisation supprimée avec succès'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
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
      title: 'Evènement',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Recherche (localisation ou description)',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                const Text('Afficher :'),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _pageSize,
                  items: PaginationConstants.pageSizes
                      .map(
                        (size) =>
                            DropdownMenuItem(value: size, child: Text('$size')),
                      )
                      .toList(),
                  onChanged: _onPageSizeChanged,
                ),
                const Spacer(),
                Text('Page ${_currentPage + 1} / $totalPages'),
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
          Expanded(
            child: FutureBuilder<List<EventOrganization>>(
              future: _orgsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                } else {
                  final pagedOrgs = snapshot.data ?? [];
                  if (pagedOrgs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Aucune organisation d\'événement trouvée.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Organiser un évènement'),
                            onPressed: () => _navigateToCreate(context),
                          ),
                        ],
                      ),
                    );
                  }
                  return EventOrganizationsTable(
                    organizations: pagedOrgs,
                    onEdit: _refresh,
                    onManageParticipants: (org) =>
                        _navigateToParticipants(context, org),
                    onEditOrganization: (org) => _navigateToEdit(context, org),
                    onDeleteOrganization: (org) =>
                        _deleteOrganization(context, org),
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FloatingActionButton.extended(
                  onPressed: () => _navigateToCreate(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Organiser un évènement'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
