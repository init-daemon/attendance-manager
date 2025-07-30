import 'package:flutter/material.dart';
import 'package:attendance_app/features/event_organization/widgets/event_participants_table.dart';
import 'package:attendance_app/features/event_organization/models/event_organization.dart';
import 'package:attendance_app/features/event_organization/models/event_participant.dart';
import 'package:attendance_app/services/event_table_service.dart';
import 'package:attendance_app/services/date_service.dart';
import 'package:attendance_app/core/widgets/app_layout.dart';
import 'package:attendance_app/services/event_participant_table_service.dart';
import 'package:attendance_app/services/member_table_service.dart';

class EventOrganizationParticipantsScreen extends StatefulWidget {
  final String eventOrganizationId;
  final EventOrganization? eventOrganization;

  const EventOrganizationParticipantsScreen({
    super.key,
    required this.eventOrganizationId,
    this.eventOrganization,
  });

  @override
  State<EventOrganizationParticipantsScreen> createState() =>
      _EventOrganizationParticipantsScreenState();
}

class _EventOrganizationParticipantsScreenState
    extends State<EventOrganizationParticipantsScreen> {
  String _searchQuery = '';

  Future<Map<String, int>> _getAttendanceStats(
    List<EventParticipant> participants,
  ) async {
    final presentCount = participants.where((p) => p.isPresent).length;
    final absentCount = participants.length - presentCount;

    return {
      'present': presentCount,
      'absent': absentCount,
      'total': participants.length,
    };
  }

  Widget _buildAttendanceStatsBar(int present, int absent, int total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Présents', present, Colors.green),
          _buildStatItem('Absents', absent, Colors.orange),
          _buildStatItem('Total', total, Theme.of(context).primaryColor),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.eventOrganizationId.isEmpty ||
        widget.eventOrganization == null) {
      return AppLayout(
        title: 'Participants',
        body: const Center(child: Text('Aucun événement sélectionné')),
      );
    }

    return AppLayout(
      title: 'Participants',
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FutureBuilder(
                        future: EventTableService.getById(
                          widget.eventOrganization!.eventId,
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
                        DateService.formatFrLong(
                          widget.eventOrganization!.date,
                        ),
                      ),
                      _buildInfoRow(
                        'Localisation',
                        widget.eventOrganization!.location,
                      ),
                      _buildInfoRow(
                        'Description',
                        widget.eventOrganization!.description ?? '',
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
                    children: [
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
                              widget.eventOrganizationId,
                              includeHidden: true,
                            ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          if (snapshot.hasError || !snapshot.hasData) {
                            return const SizedBox();
                          }

                          return FutureBuilder<Map<String, int>>(
                            future: _getAttendanceStats(snapshot.data!),
                            builder: (context, statsSnapshot) {
                              if (statsSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (statsSnapshot.hasError ||
                                  !statsSnapshot.hasData) {
                                return const SizedBox();
                              }

                              return _buildAttendanceStatsBar(
                                statsSnapshot.data!['present'] ?? 0,
                                statsSnapshot.data!['absent'] ?? 0,
                                statsSnapshot.data!['total'] ?? 0,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: MediaQuery.of(context).size.height * 0.6,
                child: EventParticipantsTable(
                  eventOrganizationId: widget.eventOrganizationId,
                  searchQuery: _searchQuery,
                ),
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
