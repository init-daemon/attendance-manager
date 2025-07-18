import 'package:flutter/material.dart';
import 'package:presence_manager/features/member/models/member.dart';
import 'package:presence_manager/features/member/widgets/profile_avatar.dart';
import 'package:presence_manager/core/widgets/app_layout.dart';
import 'package:presence_manager/features/member/screens/member_edit_screen.dart';
import 'package:presence_manager/features/event_organization/models/event_organization.dart';
import 'package:presence_manager/features/event_organization/models/event_participant.dart';
import 'package:presence_manager/features/event/models/event.dart';
import 'package:presence_manager/services/db_service.dart';

class _MemberStats {
  final int presentCount;
  final int absentCount;
  final List<_EventParticipation> participations;

  _MemberStats({
    required this.presentCount,
    required this.absentCount,
    required this.participations,
  });
}

class _EventParticipation {
  final String eventName;
  final DateTime date;
  final String status;

  _EventParticipation({
    required this.eventName,
    required this.date,
    required this.status,
  });
}

class MemberViewScreen extends StatefulWidget {
  final Member member;
  static const String routeName = '/members/view';

  const MemberViewScreen({super.key, required this.member});

  @override
  State<MemberViewScreen> createState() => _MemberViewScreenState();
}

class _MemberViewScreenState extends State<MemberViewScreen> {
  DateTime? startDate;
  DateTime? endDate;
  _MemberStats? orgStats;
  _MemberStats? eventStats;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => loading = true);

    final orgParticipationsMaps = await DbService.getByField(
      tableName: 'event_participants',
      field: 'individual_id',
      value: widget.member.id,
    );
    final orgs = <_EventParticipation>[];
    for (final pMap in orgParticipationsMaps) {
      final p = EventParticipant.fromMap(pMap);
      final orgMaps = await DbService.getByField(
        tableName: 'event_organizations',
        field: 'id',
        value: p.eventOrganizationId,
      );
      if (orgMaps.isEmpty) continue;
      final org = EventOrganization.fromMap(orgMaps.first);
      if (_isInInterval(org.date)) {
        final eventMaps = await DbService.getByField(
          tableName: 'events',
          field: 'id',
          value: org.eventId,
        );
        final eventName = eventMaps.isNotEmpty
            ? eventMaps.first['name'] ?? 'Événement organisé'
            : 'Événement organisé';
        orgs.add(
          _EventParticipation(
            eventName: eventName,
            date: org.date,
            status: p.isPresent ? 'Présent' : 'Absent',
          ),
        );
      }
    }
    orgs.sort((a, b) => b.date.compareTo(a.date));
    final orgPresent = orgs.where((e) => e.status == 'Présent').length;
    final orgAbsent = orgs.where((e) => e.status == 'Absent').length;

    final events = <_EventParticipation>[];
    for (final pMap in orgParticipationsMaps) {
      final p = EventParticipant.fromMap(pMap);
      final orgMaps = await DbService.getByField(
        tableName: 'event_organizations',
        field: 'id',
        value: p.eventOrganizationId,
      );
      if (orgMaps.isEmpty) continue;
      final org = EventOrganization.fromMap(orgMaps.first);
      final eventMaps = await DbService.getByField(
        tableName: 'events',
        field: 'id',
        value: org.eventId,
      );
      if (eventMaps.isEmpty) continue;
      final event = Event.fromMap(eventMaps.first);
      if (_isInInterval(event.createdAt)) {
        events.add(
          _EventParticipation(
            eventName: event.name,
            date: event.createdAt,
            status: p.isPresent ? 'Présent' : 'Absent',
          ),
        );
      }
    }
    events.sort((a, b) => b.date.compareTo(a.date));
    final eventPresent = events.where((e) => e.status == 'Présent').length;
    final eventAbsent = events.where((e) => e.status == 'Absent').length;

    setState(() {
      orgStats = _MemberStats(
        presentCount: orgPresent,
        absentCount: orgAbsent,
        participations: orgs,
      );
      eventStats = _MemberStats(
        presentCount: eventPresent,
        absentCount: eventAbsent,
        participations: events,
      );
      loading = false;
    });
  }

  bool _isInInterval(DateTime date) {
    if (startDate != null && date.isBefore(startDate!)) return false;
    if (endDate != null && date.isAfter(endDate!)) return false;
    return true;
  }

  void _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => startDate = picked);
      _loadStats();
    }
  }

  void _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => endDate = picked);
      _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final initials =
        '${member.firstName.isNotEmpty ? member.firstName[0] : ''}'
        '${member.lastName.isNotEmpty ? member.lastName[0] : ''}';

    return AppLayout(
      title: 'Détails du membre',
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _navigateToEditScreen(context),
        ),
      ],
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              ProfileAvatar(initials: initials, radius: 50),
              const SizedBox(height: 20),
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Nom', member.lastName),
                      _buildInfoRow('Prénom', member.firstName),
                      _buildInfoRow(
                        'Date de naissance',
                        '${member.birthDate.day}/${member.birthDate.month}/${member.birthDate.year}',
                      ),
                      _buildInfoRow(
                        'Statut',
                        member.isHidden ? 'Caché' : 'Visible',
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.edit),
                            label: const Text('Modifier'),
                            onPressed: () => _navigateToEditScreen(context),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.list),
                            label: const Text('Liste'),
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/members',
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
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ElevatedButton.icon(
                            icon: const Icon(Icons.date_range),
                            label: const Text('Début'),
                            onPressed: _pickStartDate,
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.date_range),
                            label: const Text('Fin'),
                            onPressed: _pickEndDate,
                          ),
                          const SizedBox(width: 8),
                          if (startDate != null || endDate != null)
                            TextButton(
                              child: const Text('Réinitialiser'),
                              onPressed: () {
                                setState(() {
                                  startDate = null;
                                  endDate = null;
                                });
                                _loadStats();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      loading
                          ? const Center(child: CircularProgressIndicator())
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Participation aux événements organisés',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[700],
                                      ),
                                ),
                                const SizedBox(height: 8),
                                _buildStatBadges(orgStats),
                                const SizedBox(height: 8),
                                _buildStatsList(orgStats, Icons.groups),
                                const Divider(height: 32),
                                Text(
                                  'Participation aux événements',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                ),
                                const SizedBox(height: 8),
                                _buildStatBadges(eventStats),
                                const SizedBox(height: 8),
                                _buildStatsList(eventStats, Icons.event),
                              ],
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

  Widget _buildStatBadges(_MemberStats? stats) {
    if (stats == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.onSecondary,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                'Présent : ${stats.presentCount}',
                style: TextStyle(
                  color: theme.colorScheme.onSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.cancel, color: theme.colorScheme.onError, size: 18),
              const SizedBox(width: 6),
              Text(
                'Absent : ${stats.absentCount}',
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsList(_MemberStats? stats, IconData icon) {
    if (stats == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(
      children: stats.participations
          .map(
            (p) => Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  icon,
                  color: p.status == 'Présent'
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.error,
                ),
                title: Text(
                  p.eventName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  '${p.status} • ${p.date.day.toString().padLeft(2, '0')}/${p.date.month.toString().padLeft(2, '0')}/${p.date.year}',
                  style: TextStyle(
                    color: p.status == 'Présent'
                        ? theme.colorScheme.secondary
                        : theme.colorScheme.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  void _navigateToEditScreen(BuildContext context) {
    Navigator.pushNamed(
      context,
      MemberEditScreen.routeName,
      arguments: widget.member,
    ).then((updatedMember) {
      if (updatedMember != null && updatedMember is Member) {
        Navigator.pop(context, updatedMember);
      }
    });
  }
}
