import 'package:flutter/material.dart';
import 'package:attendance_app/features/event_organization/models/event_participant.dart';
import 'package:attendance_app/services/event_participant_table_service.dart';
import 'package:attendance_app/services/app_db_service.dart';
import 'package:attendance_app/services/db_service.dart';
import 'dart:async';

class EventParticipantsTable extends StatefulWidget {
  final String eventOrganizationId;

  const EventParticipantsTable({super.key, required this.eventOrganizationId});

  @override
  State<EventParticipantsTable> createState() => _EventParticipantsTableState();
}

class _EventParticipantsTableState extends State<EventParticipantsTable> {
  late Future<List<EventParticipant>> _participantsFuture;

  @override
  void initState() {
    super.initState();

    _refresh();
  }

  void _refresh() {
    setState(() {
      _participantsFuture =
          EventParticipantTableService.getByEventOrganizationId(
            widget.eventOrganizationId,
          );
    });
  }

  void _addParticipant() async {
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
            WHERE m.isHidden = 0
            AND NOT EXISTS (
              SELECT 1 FROM event_participants ep
              WHERE ep.individual_id = m.id
              AND ep.event_organization_id = ?
            )
            ${searchText.trim().isNotEmpty ? "AND (m.firstName LIKE '%$searchText%' OR m.lastName LIKE '%$searchText%')" : ""}
            ORDER BY m.lastName ASC
            LIMIT $pageSize OFFSET ${currentPage * pageSize}
          ''';

      members = await DbService.rawQuery(query, whereArgs);
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text(
          'Voulez-vous vraiment supprimer ce participant de l\'événement ?',
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

  Future<String> _getMemberFullName(String memberId) async {
    final db = await AppDbService.database;
    final result = await db.query(
      'members',
      columns: ['firstName', 'lastName'],
      where: 'id = ?',
      whereArgs: [memberId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      final prenom = result.first['firstName'] ?? '';
      final nom = result.first['lastName'] ?? '';
      return '$prenom $nom'.trim();
    }
    return memberId;
  }

  @override
  Widget build(BuildContext context) {
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
              if (!snapshot.hasData) {
                return const Center(child: LinearProgressIndicator());
              }
              final participants = snapshot.data!;
              final visibleParticipants = participants
                  .where((p) => p.isHidden == false)
                  .toList();
              if (visibleParticipants.isEmpty) {
                return const Center(child: Text('Aucun participant'));
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
                      rows: visibleParticipants.map((p) {
                        return DataRow(
                          cells: [
                            DataCell(
                              FutureBuilder<String>(
                                future: _getMemberFullName(p.individualId),
                                builder: (context, snap) {
                                  if (snap.connectionState ==
                                      ConnectionState.waiting) {
                                    return const SizedBox(
                                      width: 60,
                                      height: 12,
                                      child: LinearProgressIndicator(),
                                    );
                                  }
                                  return Text(snap.data ?? p.individualId);
                                },
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
