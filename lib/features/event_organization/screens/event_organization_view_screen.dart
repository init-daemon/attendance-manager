import 'package:flutter/material.dart';
import 'package:attendance_app/features/event_organization/models/event_organization.dart';
import 'package:attendance_app/features/event_organization/models/event_participant.dart';
import 'package:attendance_app/features/member/models/member.dart';
import 'package:attendance_app/services/event_table_service.dart';
import 'package:attendance_app/services/date_service.dart';
import 'package:attendance_app/core/widgets/app_layout.dart';
import 'package:attendance_app/services/event_participant_table_service.dart';
import 'package:attendance_app/services/member_table_service.dart';

class EventOrganizationViewScreen extends StatefulWidget {
  final EventOrganization eventOrganization;

  const EventOrganizationViewScreen({
    super.key,
    required this.eventOrganization,
  });

  @override
  State<EventOrganizationViewScreen> createState() =>
      _EventOrganizationViewScreenState();
}

class _EventOrganizationViewScreenState
    extends State<EventOrganizationViewScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Détails de l\'événement',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder(
                        future: EventTableService.getById(
                          widget.eventOrganization.eventId,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(),
                            );
                          }
                          if (snapshot.hasData && snapshot.data != null) {
                            return _buildInfoRow(
                              'Événement',
                              snapshot.data!.name,
                            );
                          }
                          return _buildInfoRow('Événement', 'Non trouvé');
                        },
                      ),
                      _buildInfoRow(
                        'Date',
                        DateService.formatFrLong(widget.eventOrganization.date),
                      ),
                      _buildInfoRow(
                        'Localisation',
                        widget.eventOrganization.location,
                      ),
                      _buildInfoRow(
                        'Description',
                        widget.eventOrganization.description ?? '',
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
                                '/event-organizations/edit',
                                arguments: widget.eventOrganization,
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.list),
                            label: const Text('Liste'),
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/event-organizations',
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Participants',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Rechercher un participant',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<EventParticipant>?>(
                        future:
                            EventParticipantTableService.getByEventOrganizationId(
                              widget.eventOrganization.id,
                              includeHidden: true,
                            ),
                        builder: (context, participantsSnapshot) {
                          if (participantsSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (participantsSnapshot.hasError) {
                            return Text(
                              'Erreur: ${participantsSnapshot.error.toString()}',
                            );
                          }
                          if (!participantsSnapshot.hasData ||
                              participantsSnapshot.data!.isEmpty) {
                            return const Center(
                              child: Text('Aucun participant'),
                            );
                          }

                          final participants = participantsSnapshot.data!;
                          return FutureBuilder<Map<String, Member>>(
                            future: _getMembersDetails(participants),
                            builder: (context, membersSnapshot) {
                              if (membersSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (membersSnapshot.hasError) {
                                return Text(
                                  'Erreur: ${membersSnapshot.error.toString()}',
                                );
                              }

                              final membersMap = membersSnapshot.data ?? {};

                              final filteredParticipants = participants.where((
                                participant,
                              ) {
                                final member =
                                    membersMap[participant.individualId];
                                if (member == null) return false;
                                final fullName =
                                    '${member.firstName} ${member.lastName}'
                                        .toLowerCase();
                                return fullName.contains(_searchQuery);
                              }).toList();

                              if (filteredParticipants.isEmpty) {
                                return const Center(
                                  child: Text('Aucun résultat trouvé'),
                                );
                              }

                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columnSpacing: 20,
                                  columns: const [
                                    DataColumn(label: Text('Nom')),
                                    DataColumn(label: Text('Prénom')),
                                    DataColumn(
                                      label: Text('Statut'),
                                      numeric: true,
                                    ),
                                  ],
                                  rows: filteredParticipants.map((participant) {
                                    final member =
                                        membersMap[participant.individualId];
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(member?.lastName ?? 'N/A'),
                                        ),
                                        DataCell(
                                          Text(member?.firstName ?? 'N/A'),
                                        ),
                                        DataCell(
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: participant.isPresent
                                                  ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.2)
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .error
                                                        .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              participant.isPresent
                                                  ? 'Présent'
                                                  : 'Absent',
                                              style: TextStyle(
                                                color: participant.isPresent
                                                    ? Theme.of(
                                                        context,
                                                      ).colorScheme.primary
                                                    : Theme.of(
                                                        context,
                                                      ).colorScheme.error,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, Member>> _getMembersDetails(
    List<EventParticipant> participants,
  ) async {
    final memberIds = participants.map((p) => p.individualId).toList();
    final members = await MemberTableService.getAllMembers();
    return {
      for (var m in members.where((m) => memberIds.contains(m.id))) m.id: m,
    };
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label :', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, softWrap: true, overflow: TextOverflow.visible),
        ],
      ),
    );
  }
}
