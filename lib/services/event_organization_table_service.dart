import 'package:faker/faker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:presence_manager/features/event_organization/models/event_organization.dart';
import 'package:presence_manager/services/app_db_service.dart';
import 'package:presence_manager/services/db_service.dart';
import 'package:presence_manager/services/event_participant_table_service.dart';

class EventOrganizationTableService {
  static const String table = 'event_organizations';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE $table (
        id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL,
        description TEXT,
        date TEXT NOT NULL,
        location TEXT NOT NULL,
        FOREIGN KEY(event_id) REFERENCES events(id) ON DELETE CASCADE
      )
    ''');
    await EventParticipantTableService.createTable(db);
  }

  static Future<void> seed({int count = 10}) async {
    final db = await AppDbService.database;
    final faker = Faker();

    for (int i = 0; i < count; i++) {
      final DateTime date = faker.date.dateTime(minYear: 2020, maxYear: 2025);

      final randomEventId =
          await DbService.getRandomRow(tableName: 'events', returnIdOnly: true)
              as String?;

      if (randomEventId == null) {
        throw Exception('No events available to associate with organization');
      }

      final event = EventOrganization(
        id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
        eventId: randomEventId,
        description: faker.lorem.sentence(),
        date: date,
        location: faker.address.city(),
      );

      await db.insert(table, event.toMap());

      await EventParticipantTableService.seedForEventOrganization(event.id);
    }
  }

  static Future<int> insert(EventOrganization org) async {
    final db = await AppDbService.database;
    return await db.insert(table, org.toMap());
  }

  static Future<int> update(EventOrganization org) async {
    final db = await AppDbService.database;
    return await db.update(
      table,
      org.toMap(),
      where: 'id = ?',
      whereArgs: [org.id],
    );
  }

  static Future<int> delete(String id) async {
    final db = await AppDbService.database;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clear() async {
    final db = await AppDbService.database;
    await db.delete(table);
  }
}
