import 'package:flutter/material.dart';
import 'package:attendance_app/core/widgets/app_layout.dart';
import 'package:attendance_app/features/event/widgets/events_table.dart';
import 'package:attendance_app/features/event/models/event.dart';
import 'package:attendance_app/features/event/screens/event_create_screen.dart';
import 'package:attendance_app/shared/constants/pagination_constants.dart';
import 'package:attendance_app/services/db_service.dart';
import 'dart:async';

class EventsListScreen extends StatefulWidget {
  const EventsListScreen({super.key});

  @override
  State<EventsListScreen> createState() => _EventsListScreenState();
}

class _EventsListScreenState extends State<EventsListScreen> {
  int _currentPage = 0;
  int _pageSize = PaginationConstants.defaultPageSize;
  int _totalEvents = 0;
  late Future<List<Event>> _eventsFuture;
  String _searchText = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  void _loadEvents() {
    if (_searchText.isEmpty) {
      setState(() {
        _eventsFuture = DbService.getPaged(
          tableName: 'events',
          limit: _pageSize,
          offset: _currentPage * _pageSize,
          orderBy: 'name ASC',
        ).then((maps) => maps.map((map) => Event.fromMap(map)).toList());
        DbService.count('events').then((count) {
          setState(() {
            _totalEvents = count;
          });
        });
      });
    } else {
      setState(() {
        _eventsFuture = DbService.search(
          tableName: 'events',
          query: _searchText,
          fields: ['name'],
          limit: _pageSize,
          offset: _currentPage * _pageSize,
          orderBy: 'name ASC',
        ).then((maps) => maps.map((map) => Event.fromMap(map)).toList());
        DbService.search(
          tableName: 'events',
          query: _searchText,
          fields: ['name'],
          limit: 1000000,
          offset: 0,
        ).then((maps) {
          setState(() {
            _totalEvents = maps.length;
          });
        });
      });
    }
  }

  void _refreshEvents() {
    _loadEvents();
  }

  void _navigateToCreateScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EventCreateScreen()),
    );
    _refreshEvents();
  }

  void _onPageSizeChanged(int? value) {
    if (value != null) {
      setState(() {
        _pageSize = value;
        _currentPage = 0;
      });
      _loadEvents();
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadEvents();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _searchText = value;
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _currentPage = 0;
      _loadEvents();
    });
  }

  Future<void> _deleteEvent(BuildContext context, Event event) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
          "Supprimer ce type d'événement supprimera également tous les événements liés. Souhaitez-vous vraiment procéder ?",
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
        where: 'event_id = ?',
        whereArgs: [event.id],
      );
      await DbService.deleteById(tableName: 'events', id: event.id);
      _refreshEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Événement supprimé avec succès'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  int get totalPages => (_totalEvents / _pageSize).ceil();

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Liste des Événements',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Recherche (nom de l\'événement)',
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
            child: FutureBuilder<List<Event>>(
              future: _eventsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                } else {
                  final pagedEvents = snapshot.data ?? [];
                  if (pagedEvents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Aucun événement trouvé.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Créer un événement'),
                            onPressed: () => _navigateToCreateScreen(context),
                          ),
                        ],
                      ),
                    );
                  }
                  return EventsTable(
                    events: pagedEvents,
                    onEdit: _refreshEvents,
                    onDelete: (event) => _deleteEvent(context, event),
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
                  onPressed: () => _navigateToCreateScreen(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Créer un événement'),
                ),
              ],
            ),
          ),
        ],
      ),
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _navigateToCreateScreen(context),
        ),
      ],
    );
  }
}
