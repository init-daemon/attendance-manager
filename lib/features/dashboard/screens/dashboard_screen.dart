import 'package:flutter/material.dart';
import 'package:presence_manager/core/widgets/app_layout.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Dashboard',
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Bienvenue sur le Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Accédez rapidement aux membres, événements et organisations.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
