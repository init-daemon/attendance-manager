import 'package:attendance_app/services/date_service.dart';
import 'package:flutter/material.dart';
import 'package:attendance_app/features/event_organization/models/event_participant.dart';
import 'package:attendance_app/services/event_participant_table_service.dart';
import 'package:attendance_app/services/app_db_service.dart';
import 'package:attendance_app/services/db_service.dart';
import 'package:attendance_app/services/member_table_service.dart';
import 'package:attendance_app/features/member/models/member.dart';
import 'dart:async';

class EventParticipantsTable extends StatefulWidget {
  final String eventOrganizationId;
  final String searchQuery;

  const EventParticipantsTable({
    super.key,
    required this.eventOrganizationId,
    this.searchQuery = '',
  });

  @override
  State<EventParticipantsTable> createState() => _EventParticipantsTableState();
}

class _EventParticipantsTableState extends State<EventParticipantsTable> {
  late Future<List<EventParticipant>> _participantsFuture;
  DateTime? _eventDate;
  bool _isLoading = true;
  Map<String, Member> _membersCache = {};

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final db = await AppDbService.database;
      final eventOrg = await db.query(
        'event_organizations',
        where: 'id = ?',
        whereArgs: [widget.eventOrganizationId],
        limit: 1,
      );

      if (eventOrg.isNotEmpty) {
        _eventDate = DateTime.parse(eventOrg.first['date'] as String);
        _refresh();
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _refresh() {
    if (_eventDate == null) return;

    setState(() {
      _isLoading = true;
      _participantsFuture = _loadParticipantsWithMembers();
    });
  }

  Future<List<EventParticipant>> _loadParticipantsWithMembers() async {
    final participants =
        await EventParticipantTableService.getByEventOrganizationId(
          widget.eventOrganizationId,
          eventDate: _eventDate!,
        );

    final memberIds = participants.map((p) => p.individualId).toList();
    final members = await MemberTableService.getAllMembers();
    _membersCache = {
      for (var m in members.where((m) => memberIds.contains(m.id))) m.id: m,
    };

    return participants;
  }

  List<EventParticipant> _filterParticipants(
    List<EventParticipant> participants,
  ) {
    if (widget.searchQuery.isEmpty) return participants;

    return participants.where((participant) {
      final member = _membersCache[participant.individualId];
      if (member == null) return false;
      final fullName = '${member.firstName} ${member.lastName}'.toLowerCase();
      return fullName.contains(widget.searchQuery.toLowerCase());
    }).toList();
  }

  void _addParticipant() async {
    if (_eventDate == null) return;

    String? selectedId;
    int pageSize = 10;
    int currentPage = 0;
    List<Map<String, dynamic>> members = [];
    String searchText = '';

    final existingParticipants =
        await EventParticipantTableService.getByEventOrganizationId(
          widget.eventOrganizationId,
        );
    final selectedIds = existingParticipants.map((p) => p.individualId).toSet();

    Future<void> loadMembers() async {
      final whereArgs = [widget.eventOrganizationId];

      final query =
          '''
        SELECT m.* FROM members m
        WHERE (m.isHidden = 0 OR 
              (m.isHidden = 1 AND (m.hiddenAt IS NULL OR m.hiddenAt > ?)))
        AND NOT EXISTS (
          SELECT 1 FROM event_participants ep
          WHERE ep.individual_id = m.id
          AND ep.event_organization_id = ?
        )
        ${searchText.trim().isNotEmpty ? "AND (m.firstName LIKE '%$searchText%' OR m.lastName LIKE '%$searchText%')" : ""}
        ORDER BY m.lastName ASC
        LIMIT $pageSize OFFSET ${currentPage * pageSize}
      ''';

      members = await DbService.rawQuery(query, [
        _eventDate!.toIso8601String(),
        ...whereArgs,
      ]);
    }

    await loadMembers();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Timer? localDebounce;
            return AlertDialog(
              title: const Text('Ajouter un participant'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Recherche (nom ou prénom)',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        localDebounce?.cancel();
                        searchText = value;
                        localDebounce = Timer(
                          const Duration(milliseconds: 500),
                          () async {
                            currentPage = 0;
                            await loadMembers();
                            setState(() {});
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final prenom = member['firstName'] ?? '';
                          final nom = member['lastName'] ?? '';
                          final displayName = ('$prenom $nom').trim().isEmpty
                              ? member['id'].toString()
                              : '$prenom $nom';
                          return ListTile(
                            title: Text(displayName),
                            onTap: () {
                              selectedId = member['id'] is String
                                  ? member['id'] as String
                                  : member['id'].toString();
                              Navigator.pop(context);
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
                                  await loadMembers();
                                  setState(() {});
                                }
                              : null,
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: members.length == pageSize
                              ? () async {
                                  currentPage++;
                                  await loadMembers();
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

    if (selectedId != null) {
      final existing =
          await EventParticipantTableService.getByEventOrganizationId(
            widget.eventOrganizationId,
          );
      final alreadyAdded = existing.any((p) => p.individualId == selectedId);
      if (!alreadyAdded) {
        await EventParticipantTableService.insert(
          EventParticipant(
            eventOrganizationId: widget.eventOrganizationId,
            individualId: selectedId!,
            isPresent: false,
          ),
        );
        _refresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ce membre est déjà participant.')),
        );
      }
    }
  }

  void _removeParticipant(EventParticipant participant) async {
    final member = await DbService.getByField(
      tableName: 'members',
      field: 'id',
      value: participant.individualId,
    );

    if (member.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ce membre n\'existe plus')));
      return;
    }

    final isHidden = member.first['isHidden'] == 1;
    final hiddenAt = member.first['hiddenAt'] != null
        ? DateTime.parse(member.first['hiddenAt'] as String)
        : null;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voulez-vous vraiment supprimer ce participant de l\'événement ?',
            ),
            if (isHidden && hiddenAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Ce membre a été supprimé le ${DateService.formatFr(hiddenAt, withHour: false)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Annuler'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Supprimer'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await EventParticipantTableService.delete(
        participant.eventOrganizationId,
        participant.individualId,
      );
      _refresh();
    }
  }

  void _togglePresence(EventParticipant participant) async {
    participant.isPresent = !participant.isPresent;
    await EventParticipantTableService.update(participant);
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _eventDate == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_eventDate == null) {
      return const Center(
        child: Text('Impossible de charger les données de l\'événement'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Participants',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 12),
            IconButton(
              icon: const Icon(Icons.person_add, size: 20),
              onPressed: _addParticipant,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: FutureBuilder<List<EventParticipant>>(
            future: _participantsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Erreur: ${snapshot.error}'));
              }

              final participants = snapshot.data ?? [];
              final filteredParticipants = _filterParticipants(participants);

              if (filteredParticipants.isEmpty) {
                return Center(
                  child: Text(
                    widget.searchQuery.isEmpty
                        ? 'Aucun participant'
                        : 'Aucun résultat trouvé',
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: DataTable(
                      columnSpacing: 20,
                      dataRowHeight: 48,
                      headingRowHeight: 40,
                      columns: const [
                        DataColumn(label: Text('Nom')),
                        DataColumn(label: Text('Présent')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: filteredParticipants.map((p) {
                        final member = _membersCache[p.individualId];
                        final displayName = member != null
                            ? '${member.firstName} ${member.lastName}'
                            : p.individualId;

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                displayName,
                                style: p.isHidden
                                    ? TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.error,
                                        fontStyle: FontStyle.italic,
                                      )
                                    : null,
                              ),
                            ),
                            DataCell(
                              Checkbox(
                                value: p.isPresent,
                                onChanged: (_) => _togglePresence(p),
                              ),
                            ),
                            DataCell(
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () => _removeParticipant(p),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
