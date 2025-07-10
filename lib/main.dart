// lib/main.dart
import 'package:flutter/material.dart';
import 'package:presence_manager/screens/individuals_list_screen.dart';

void main() {
  runApp(const PresenceManagerApp());
}

class PresenceManagerApp extends StatelessWidget {
  const PresenceManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion de Présence',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const IndividualsListScreen(),
    );
  }
}
