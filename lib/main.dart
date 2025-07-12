// lib/main.dart
import 'package:flutter/material.dart';
import 'package:presence_manager/core/app/app_router.dart';
import 'package:presence_manager/services/individual_db_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final individuals = await IndividualDbService.getAllIndividuals();

  if (individuals.isEmpty) {
    await IndividualDbService.seedDatabase(count: 10);
  }
  runApp(const PresenceManagerApp());
}

class PresenceManagerApp extends StatelessWidget {
  const PresenceManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Presence Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      onGenerateRoute: AppRouter.generateRoute,
      initialRoute: '/individuals',
    );
  }
}
