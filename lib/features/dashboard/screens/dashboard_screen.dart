import 'package:flutter/material.dart';
import 'package:attendance_app/core/widgets/app_layout.dart';
import 'package:attendance_app/features/dashboard/widgets/dashboard_card.dart';
import 'package:attendance_app/services/db_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int memberCount = 0;
  int eventCount = 0;
  int eventOrgCount = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final db = await DbService.getDatabase();
    final mResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM members WHERE isHidden = 0',
    );
    final m = mResult.first['count'] as int? ?? 0;
    final e = await DbService.count('events');
    final eo = await DbService.count('event_organizations');
    setState(() {
      memberCount = m;
      eventCount = e;
      eventOrgCount = eo;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Dashboard',
      body: Center(
        child: loading
            ? const CircularProgressIndicator()
            : Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  DashboardCard(
                    count: memberCount,
                    label: 'Membres',
                    routeName: '/members',
                    color: Colors.blue,
                    icon: Icons.people,
                  ),
                  DashboardCard(
                    count: eventCount,
                    label: 'Liste d\'événements',
                    routeName: '/events',
                    color: Colors.green,
                    icon: Icons.event,
                  ),
                  DashboardCard(
                    count: eventOrgCount,
                    label: 'Événements organisés',
                    routeName: '/event-organizations',
                    color: Colors.orange,
                    icon: Icons.groups,
                  ),
                ],
              ),
      ),
    );
  }
}
