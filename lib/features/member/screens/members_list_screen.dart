import 'package:flutter/material.dart';
import 'package:presence_manager/features/member/widgets/members_table.dart';
import 'package:presence_manager/services/db_service.dart';
import 'package:presence_manager/features/member/models/member.dart';
import 'package:presence_manager/features/member/screens/member_create_screen.dart';
import 'package:presence_manager/core/widgets/app_layout.dart';
import 'package:presence_manager/shared/constants/pagination_constants.dart';
import 'dart:async';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  int _currentPage = 0;
  int _pageSize = PaginationConstants.defaultPageSize;
  int _totalMembers = 0;
  late Future<List<Member>> _membersFuture;
  String _searchText = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    if (_searchText.isEmpty) {
      setState(() {
        _membersFuture = DbService.getPaged(
          tableName: 'members',
          limit: _pageSize,
          offset: _currentPage * _pageSize,
          orderBy: 'lastName ASC',
        ).then((maps) => maps.map((map) => Member.fromMap(map)).toList());
        DbService.count('members').then((count) {
          setState(() {
            _totalMembers = count;
          });
        });
      });
    } else {
      setState(() {
        _membersFuture = DbService.search(
          tableName: 'members',
          query: _searchText,
          fields: ['firstName', 'lastName'],
          limit: _pageSize,
          offset: _currentPage * _pageSize,
          orderBy: 'lastName ASC',
        ).then((maps) => maps.map((map) => Member.fromMap(map)).toList());
        DbService.search(
          tableName: 'members',
          query: _searchText,
          fields: ['firstName', 'lastName'],
          limit: 1000000,
          offset: 0,
        ).then((maps) {
          setState(() {
            _totalMembers = maps.length;
          });
        });
      });
    }
  }

  void _refreshMembers() {
    _loadMembers();
  }

  void _navigateToCreateScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MemberCreateScreen()),
    );
    _refreshMembers();
  }

  void _onPageSizeChanged(int? value) {
    if (value != null) {
      setState(() {
        _pageSize = value;
        _currentPage = 0;
      });
      _loadMembers();
    }
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
    _loadMembers();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _searchText = value;
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _currentPage = 0;
      _loadMembers();
    });
  }

  int get totalPages => (_totalMembers / _pageSize).ceil();

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Liste des Membres',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Recherche (nom ou prénom)',
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
            child: FutureBuilder<List<Member>>(
              future: _membersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Erreur: ${snapshot.error}'));
                } else {
                  final pagedMembers = snapshot.data ?? [];
                  if (pagedMembers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Aucun membre trouvé.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Créer un membre'),
                            onPressed: () => _navigateToCreateScreen(context),
                          ),
                        ],
                      ),
                    );
                  }
                  return MembersTable(
                    members: pagedMembers,
                    onEdit: _refreshMembers,
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
                  label: const Text('Créer un membre'),
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
