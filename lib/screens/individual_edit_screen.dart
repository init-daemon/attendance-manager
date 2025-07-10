// lib/screens/individual_edit_screen.dart
import 'package:flutter/material.dart';
import '../components/individual_form.dart';
import '../models/individual.dart';

class IndividualEditScreen extends StatelessWidget {
  final Individual individual;

  const IndividualEditScreen({super.key, required this.individual});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Modifier un individu')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: IndividualForm(
          individual: individual,
          onSave: (updatedIndividual) {
            // TODO: Implémenter la sauvegarde des modifications
            Navigator.pop(context, updatedIndividual);
          },
        ),
      ),
    );
  }
}
