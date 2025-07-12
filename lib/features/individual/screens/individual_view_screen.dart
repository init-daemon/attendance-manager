import 'package:flutter/material.dart';
import '../models/individual.dart';
import '../widgets/profile_avatar.dart';
import '../../../core/widgets/app_layout.dart'; // Import du layout commun
import '../../individual/screens/individual_edit_screen.dart';

class IndividualViewScreen extends StatelessWidget {
  final Individual individual;
  static const String routeName = '/individuals/view'; // Nom de route constant

  const IndividualViewScreen({super.key, required this.individual});

  String get initials =>
      '${individual.firstName.isNotEmpty ? individual.firstName[0] : ''}'
      '${individual.lastName.isNotEmpty ? individual.lastName[0] : ''}';

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Détails de l\'individu',
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
                      _buildInfoRow('Nom', individual.lastName),
                      _buildInfoRow('Prénom', individual.firstName),
                      _buildInfoRow(
                        'Date de naissance',
                        '${individual.birthDate.day}/${individual.birthDate.month}/${individual.birthDate.year}',
                      ),
                      _buildInfoRow(
                        'Statut',
                        individual.isHidden ? 'Caché' : 'Visible',
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

  void _navigateToEditScreen(BuildContext context) {
    Navigator.pushNamed(
      context,
      IndividualEditScreen.routeName,
      arguments: individual,
    ).then((updatedIndividual) {
      if (updatedIndividual != null && updatedIndividual is Individual) {
        Navigator.pop(context, updatedIndividual);
      }
    });
  }

  // Méthode statique pour faciliter la navigation
  static void navigate(BuildContext context, Individual individual) {
    Navigator.pushNamed(context, routeName, arguments: individual);
  }
}
