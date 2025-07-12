// lib/screens/individual_create_screen.dart
import 'package:flutter/material.dart';
import '../widgets/individual_form.dart';
import '../models/individual.dart';
import '../../../services/individual_db_service.dart';

class IndividualCreateScreen extends StatefulWidget {
  const IndividualCreateScreen({super.key});

  @override
  State<IndividualCreateScreen> createState() => _IndividualCreateScreenState();
}

class _IndividualCreateScreenState extends State<IndividualCreateScreen> {
  void _saveIndividual(Individual individual) async {
    await IndividualDbService.insertIndividual(individual);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer un nouvel individu')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: IndividualForm(onSave: _saveIndividual),
      ),
    );
  }
}
