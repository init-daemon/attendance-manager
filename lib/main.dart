// lib/main.dart
import 'package:flutter/material.dart';
import 'package:presence_manager/core/app/app_router.dart';

void main() {
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
