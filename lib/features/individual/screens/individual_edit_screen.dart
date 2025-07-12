// lib/screens/individual_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:presence_manager/features/individual/screens/individual_view_screen.dart';
import '../widgets/individual_form.dart';
import '../models/individual.dart';

class IndividualEditScreen extends StatelessWidget {
  final Individual individual;
  static const String routeName = '/individuals/edit';

  const IndividualEditScreen({super.key, required this.individual});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier un individu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              // Après sauvegarde réussie :
              Navigator.pop(
                context,
                IndividualViewScreen(individual: individual),
              );
            },
          ),
        ],
      ),
      body: IndividualForm(
        individual: individual,
        onSave: (updated) => Navigator.pop(context, updated),
      ),
    );
  }
}
