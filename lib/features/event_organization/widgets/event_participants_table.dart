import 'package:flutter/material.dart';
import 'package:presence_manager/features/event_organization/models/event_participant.dart';
import 'package:presence_manager/services/event_participant_table_service.dart';
import 'package:presence_manager/services/app_db_service.dart';

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
    // TODO:implémenter la recherche et sélection d'un individu
    // await EventParticipantTableService.insert(EventParticipant(eventOrganizationId: widget.eventOrganizationId, individualId: selectedId));
    // _refresh();
  }

  void _removeParticipant(EventParticipant participant) async {
    await EventParticipantTableService.delete(
      participant.eventOrganizationId,
      participant.individualId,
    );
    _refresh();
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Participants',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.person_add),
              onPressed: _addParticipant,
            ),
          ],
        ),
        FutureBuilder<List<EventParticipant>>(
          future: _participantsFuture,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const LinearProgressIndicator();
            }
            final participants = snapshot.data!;
            if (participants.isEmpty) {
              return const Text('Aucun participant');
            }
            return DataTable(
              columns: const [
                DataColumn(label: Text('Nom')),
                DataColumn(label: Text('Présent')),
                DataColumn(label: Text('Actions')),
              ],
              rows: participants.map((p) {
                return DataRow(
                  cells: [
                    DataCell(
                      FutureBuilder<String>(
                        future: _getMemberFullName(p.individualId),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
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
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeParticipant(p),
                      ),
                    ),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
