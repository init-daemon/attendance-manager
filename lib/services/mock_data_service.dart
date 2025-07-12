import 'dart:convert';
import 'package:flutter/services.dart';
import '../features/individual/models/individual.dart';

class MockDataService {
  static Future<List<Individual>> loadIndividuals() async {
    final jsonString = await rootBundle.loadString(
      'assets/mock_data/individuals.json',
    );
    final List<dynamic> jsonData = json.decode(jsonString);

    return jsonData
        .map(
          (item) => Individual(
            id: item['id'],
            firstName: item['firstName'],
            lastName: item['lastName'],
            birthDate: DateTime.parse(item['birthDate']),
            isHidden: item['isHidden'],
          ),
        )
        .toList();
  }
}
