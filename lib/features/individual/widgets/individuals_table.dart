import 'package:flutter/material.dart';
import '../models/individual.dart';
// import '../screens/individual_edit_screen.dart';
import '../screens/individual_view_screen.dart';

class IndividualsTable extends StatelessWidget {
  final List<Individual> individuals;

  const IndividualsTable({super.key, required this.individuals});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Nom')),
          DataColumn(label: Text('Prénom')),
          DataColumn(label: Text('Date de naissance')),
          DataColumn(label: Text('Actions')),
        ],
        rows: individuals.map((individual) {
          return DataRow(
            cells: [
              DataCell(Text(individual.lastName)),
              DataCell(Text(individual.firstName)),
              DataCell(Text(individual.birthDate.toString())),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                IndividualViewScreen(individual: individual),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () async {
                        final result = await Navigator.pushNamed(
                          context,
                          '/individuals/edit',
                          arguments: individual,
                        );

                        if (result != null && result is Individual) {
                          // Mettez à jour votre liste si besoin
                          // setState(() {
                          //   individuals[individuals.indexOf(individual)] =
                          //       result;
                          // });
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.hide_image),
                      onPressed: () {
                        // TODO: Gérer le hide
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
