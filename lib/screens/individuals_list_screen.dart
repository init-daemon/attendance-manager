import 'package:flutter/material.dart';
import '../components/individuals_table.dart';
import '../services/mock_data_service.dart';
import '../models/individual.dart';
import 'individual_create_screen.dart';

// import 'individual_create_screen.dart';

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

  void _navigateToCreateScreen(BuildContext context) {
    print('click');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IndividualCreateScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des Individus'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Créer un nouvel individu',
            onPressed: () => _navigateToCreateScreen(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Individual>>(
        future: _individualsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          } else {
            return IndividualsTable(individuals: snapshot.data!);
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateScreen(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}
