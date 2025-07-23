import 'package:flutter/material.dart';
import 'package:attendance_app/features/member/models/member.dart';
import 'package:attendance_app/features/member/widgets/profile_avatar.dart';
import 'package:attendance_app/core/widgets/app_layout.dart';
import 'package:attendance_app/features/member/screens/member_edit_screen.dart';
import 'package:attendance_app/services/db_service.dart';
import 'package:attendance_app/shared/constants/pagination_constants.dart';

class _EventStat {
  final String eventName;
  final int presentCount;
  final int absentCount;

  _EventStat({
    required this.eventName,
    required this.presentCount,
    required this.absentCount,
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
  bool loading = true;
  int eventCurrentPage = 0;
  int eventPageSize = PaginationConstants.defaultPageSize;
  List<_EventStat> eventStats = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => loading = true);

    final participantMaps = await DbService.getByField(
      tableName: 'event_participants',
      field: 'individual_id',
      value: widget.member.id,
    );

    final orgIds = participantMaps
        .map((p) => p['event_organization_id'] as String)
        .toSet()
        .toList();
    final orgMaps = <String, Map<String, dynamic>>{};
    for (final orgId in orgIds) {
      final orgList = await DbService.getByField(
        tableName: 'event_organizations',
        field: 'id',
        value: orgId,
      );
      if (orgList.isNotEmpty) {
        orgMaps[orgId] = orgList.first;
      }
    }

    final Map<String, List<Map<String, dynamic>>> eventGroups = {};
    for (final p in participantMaps) {
      final orgId = p['event_organization_id'] as String;
      final org = orgMaps[orgId];
      if (org == null) continue;
      final eventId = org['event_id'] as String;
      final orgDate = DateTime.parse(org['date']);
      if (!_isInInterval(orgDate)) continue;
      eventGroups.putIfAbsent(eventId, () => []).add(p);
    }

    final List<_EventStat> stats = [];
    for (final eventId in eventGroups.keys) {
      final eventMapList = await DbService.getByField(
        tableName: 'events',
        field: 'id',
        value: eventId,
      );
      final eventName = eventMapList.isNotEmpty
          ? eventMapList.first['name'] ?? 'Événement'
          : 'Événement';
      final group = eventGroups[eventId]!;
      final presentCount = group
          .where((p) => (p['is_present'] ?? 0) == 1)
          .length;
      final absentCount = group
          .where((p) => (p['is_present'] ?? 0) == 0)
          .length;
      stats.add(
        _EventStat(
          eventName: eventName,
          presentCount: presentCount,
          absentCount: absentCount,
        ),
      );
    }

    setState(() {
      eventStats = stats;
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
                        member.birthDate != null
                            ? '${member.birthDate?.day}/${member.birthDate?.month}/${member.birthDate?.year}'
                            : 'Non spécifiée',
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
                                  'Participation aux événements',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text('Afficher :'),
                                    const SizedBox(width: 8),
                                    DropdownButton<int>(
                                      value: eventPageSize,
                                      items: PaginationConstants.pageSizes
                                          .map(
                                            (size) => DropdownMenuItem(
                                              value: size,
                                              child: Text('$size'),
                                            ),
                                          )
                                          .toList(),
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(() {
                                            eventPageSize = value;
                                            eventCurrentPage = 0;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                _buildEventStatsPaged(),
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

  Widget _buildEventStatsPaged() {
    final theme = Theme.of(context);
    final totalItems = eventStats.length;
    final totalPages = (totalItems / eventPageSize).ceil();
    final start = eventCurrentPage * eventPageSize;
    final end = (start + eventPageSize).clamp(0, totalItems);
    final pageItems = eventStats.sublist(start, end);

    return Column(
      children: [
        ...pageItems.map(
          (stat) => Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.event),
              title: Text(
                stat.eventName,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                          'Présent : ${stat.presentCount}',
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.cancel,
                          color: theme.colorScheme.onError,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Absent : ${stat.absentCount}',
                          style: TextStyle(
                            color: theme.colorScheme.onError,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.group,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Participations : ${stat.presentCount + stat.absentCount}',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Page précédente',
                  onPressed: eventCurrentPage > 0
                      ? () => setState(() => eventCurrentPage -= 1)
                      : null,
                ),
                Text(
                  'Page ${eventCurrentPage + 1} / $totalPages',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Page suivante',
                  onPressed: eventCurrentPage < totalPages - 1
                      ? () => setState(() => eventCurrentPage += 1)
                      : null,
                ),
              ],
            ),
          ),
      ],
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
