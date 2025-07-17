import 'package:flutter/material.dart';
import 'package:presence_manager/core/widgets/app_layout.dart';
import 'package:presence_manager/features/dashboard/widgets/dashboard_card.dart';
import 'package:presence_manager/services/db_service.dart';

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
    final m = await DbService.count('members');
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
                    color: Colors.blue,
                    icon: Icons.people,
                  ),
                  DashboardCard(
                    count: eventCount,
                    label: 'Événements',
                    color: Colors.green,
                    icon: Icons.event,
                  ),
                  DashboardCard(
                    count: eventOrgCount,
                    label: 'Événements organisés',
                    color: Colors.orange,
                    icon: Icons.groups,
                  ),
                ],
              ),
      ),
    );
  }
}
