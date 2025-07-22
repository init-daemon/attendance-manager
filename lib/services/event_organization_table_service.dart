import 'package:faker/faker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:attendance_app/features/event_organization/models/event_organization.dart';
import 'package:attendance_app/services/app_db_service.dart';
import 'package:attendance_app/services/db_service.dart';
import 'package:attendance_app/services/event_participant_table_service.dart';

class EventOrganizationTableService {
  static const String table = 'event_organizations';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS event_organizations(
        id TEXT PRIMARY KEY,
        event_id TEXT,
        member_id TEXT,
        date TEXT,
        description TEXT,
        location TEXT,
        FOREIGN KEY(event_id) REFERENCES events(id) ON DELETE CASCADE,
        FOREIGN KEY(member_id) REFERENCES members(id) ON DELETE CASCADE
      )
    ''');
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

  static Future<bool> checkSchema(Database db) async {
    const expected = [
      {'name': 'id', 'type': 'TEXT'},
      {'name': 'event_id', 'type': 'TEXT'},
      {'name': 'member_id', 'type': 'TEXT'},
      {'name': 'date', 'type': 'TEXT'},
      {'name': 'description', 'type': 'TEXT'},
      {'name': 'location', 'type': 'TEXT'},
    ];
    final info = await db.rawQuery("PRAGMA table_info(event_organizations)");
    if (info.length != expected.length) return false;
    for (var i = 0; i < expected.length; i++) {
      if (info[i]['name'] != expected[i]['name'] ||
          !(info[i]['type'] as String).toUpperCase().contains(
            expected[i]['type']!,
          )) {
        return false;
      }
    }
    return true;
  }
}
