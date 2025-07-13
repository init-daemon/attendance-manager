import 'package:flutter/material.dart';
import '../widgets/individuals_table.dart';
import '../../../services/mock_data_service.dart';
import '../models/individual.dart';
import 'individual_create_screen.dart';
import 'package:presence_manager/core/widgets/app_layout.dart';

class IndividualsListScreen extends StatefulWidget {
  const IndividualsListScreen({super.key});

  @override
  State<IndividualsListScreen> createState() => _IndividualsListScreenState();
}

class _IndividualsListScreenState extends State<IndividualsListScreen> {
  late Future<List<Individual>> _individualsFuture;

  @override
  void initState() {
    super.initState();
    _individualsFuture = MockDataService.loadIndividuals();
  }

  void _refreshIndividuals() {
    setState(() {
      _individualsFuture = MockDataService.loadIndividuals();
    });
  }

  void _navigateToCreateScreen(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IndividualCreateScreen()),
    );
    _refreshIndividuals();
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      title: 'Liste des Individus',
      body: FutureBuilder<List<Individual>>(
        future: _individualsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            return Column(
              children: [
                Expanded(
                  child: IndividualsTable(
                    individuals: snapshot.data!,
                    onEdit: _refreshIndividuals,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton.extended(
                        onPressed: () => _navigateToCreateScreen(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Créer un individu'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          throw Exception(
                            'Test Exception: Ceci est une erreur volontaire',
                          );
                        },
                        icon: const Icon(Icons.error),
                        label: const Text('Test Erreur'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _navigateToCreateScreen(context),
        ),
      ],
    );
  }
}
