import 'package:flutter/material.dart';
import 'package:attendance_app/features/member/widgets/members_table.dart';
import 'package:attendance_app/services/db_service.dart';
import 'package:attendance_app/features/member/models/member.dart';
import 'package:attendance_app/features/member/screens/member_create_screen.dart';
import 'package:attendance_app/core/widgets/app_layout.dart';
import 'package:attendance_app/shared/constants/pagination_constants.dart';
import 'package:attendance_app/services/member_table_service.dart';
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
  String _hiddenFilter = 'visible';
  int _duplicateCount = 0;
  int _importedCount = 0;
  bool _isImporting = false;
  String? _importMessage;
  bool _showImportInfo = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() {
    String? where;
    List<dynamic>? whereArgs;

    if (_hiddenFilter == 'visible') {
      where = 'isHidden = ?';
      whereArgs = [0];
    } else if (_hiddenFilter == 'hidden') {
      where = 'isHidden = ?';
      whereArgs = [1];
    }

    Future<List<Map<String, dynamic>>> future;
    if (_searchText.isEmpty) {
      future = DbService.getPaged(
        tableName: 'members',
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        orderBy: 'lastName ASC',
      );
      if (where != null) {
        future = future.then(
          (list) => list.where((m) => m['isHidden'] == whereArgs![0]).toList(),
        );
      }
      setState(() {
        _membersFuture = future.then(
          (maps) => maps.map((map) => Member.fromMap(map)).toList(),
        );
        DbService.count('members').then((count) {
          setState(() {
            _totalMembers = count;
          });
        });
      });
    } else {
      future = DbService.search(
        tableName: 'members',
        query: _searchText,
        fields: ['firstName', 'lastName'],
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        orderBy: 'lastName ASC',
      );
      if (where != null) {
        future = future.then(
          (list) => list.where((m) => m['isHidden'] == whereArgs![0]).toList(),
        );
      }
      setState(() {
        _membersFuture = future.then(
          (maps) => maps.map((map) => Member.fromMap(map)).toList(),
        );
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

  Future<void> _handleImport() async {
    setState(() {
      _isImporting = true;
      _importMessage = null;
      _duplicateCount = 0;
      _importedCount = 0;
    });

    final result = await MemberTableService.importMembersFromExcel();

    setState(() {
      _isImporting = false;
      _importMessage = result['message'];
      _duplicateCount = (result['duplicates'] as List?)?.length ?? 0;
      _importedCount = (result['importedCount'] as int?) ?? 0;
    });

    if (result['success'] == true) {
      _loadMembers();
    }
  }

  void _toggleImportInfo() {
    setState(() {
      _showImportInfo = !_showImportInfo;
    });
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

  Widget _buildImportInstructions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Structure du fichier Excel attendu :',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('Colonne 1: Nom (obligatoire)'),
            const Text('Colonne 2: Prénom (obligatoire)'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _handleImport,
              child: _isImporting
                  ? const CircularProgressIndicator()
                  : const Text('Sélectionner un fichier Excel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _importMessage!,
          style: TextStyle(
            color: _importMessage!.contains('Erreur')
                ? Colors.red
                : Colors.green,
          ),
        ),
        if (_importedCount > 0 || _duplicateCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Membres importés: $_importedCount | Doublons non importés: $_duplicateCount',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }

  Widget _buildSearchAndPagination() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Recherche (nom ou prénom)',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _hiddenFilter,
                items: const [
                  DropdownMenuItem(
                    value: 'visible',
                    child: Text('Membre actif'),
                  ),
                  DropdownMenuItem(value: 'all', child: Text('Tous')),
                  DropdownMenuItem(value: 'hidden', child: Text('Corbeille')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _hiddenFilter = value;
                      _currentPage = 0;
                    });
                    _loadMembers();
                  }
                },
              ),
            ],
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Liste des Membres',
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                icon: const Icon(Icons.upload),
                                label: const Text('Importer depuis Excel'),
                                onPressed: _toggleImportInfo,
                              ),
                            ],
                          ),
                        ),

                        if (_showImportInfo)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: _buildImportInstructions(),
                          ),

                        if (_importMessage != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildImportMessage(),
                          ),
                      ],
                    ),

                    _buildSearchAndPagination(),

                    Flexible(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        constraints: BoxConstraints(
                          minHeight: 100,
                          maxHeight: constraints.maxHeight * 0.6,
                        ),
                        child: FutureBuilder<List<Member>>(
                          future: _membersFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text('Erreur: ${snapshot.error}'),
                              );
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
                                        onPressed: () =>
                                            _navigateToCreateScreen(context),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: MembersTable(
                                  members: pagedMembers,
                                  onEdit: _refreshMembers,
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FloatingActionButton.extended(
                        onPressed: () => _navigateToCreateScreen(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Créer un membre'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
