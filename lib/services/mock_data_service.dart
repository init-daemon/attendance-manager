import '../features/individual/models/individual.dart';
import 'individual_db_service.dart';

class MockDataService {
  static Future<List<Individual>> loadIndividuals() async {
    final db = await IndividualDbService.database;
    final List<Map<String, dynamic>> maps = await db.query('individuals');
    return maps
        .map(
          (item) => Individual(
            id: item['id'],
            firstName: item['firstName'],
            lastName: item['lastName'],
            birthDate: DateTime.parse(item['birthDate']),
            isHidden: item['isHidden'] == 1,
          ),
        )
        .toList();
  }
}
