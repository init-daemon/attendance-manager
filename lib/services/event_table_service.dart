import 'package:faker/faker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:attendance_app/features/event/models/event.dart';
import 'package:attendance_app/services/app_db_service.dart';

class EventTableService {
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS events(
        id TEXT PRIMARY KEY,
        name TEXT,
        createdAt TEXT,
        date TEXT,
        location TEXT
      )
    ''');
  }

  static Future<void> clear() async {
    final db = await AppDbService.database;

    await db.delete('events');
  }

  static Future<void> seed({int count = 10}) async {
    final db = await AppDbService.database;
    final faker = Faker();

    for (int i = 0; i < count; i++) {
      final event = Event(
        id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
        name: faker.lorem.words(2).join(' '),
        createdAt: DateTime.now(),
      );

      await db.insert('events', event.toMap());
    }
  }

  static Future<void> insert(Event event) async {
    final db = await AppDbService.database;

    await db.insert(
      'events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> update(Event event) async {
    final db = await AppDbService.database;

    await db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    );
  }

  static Future<void> delete(String id) async {
    final db = await AppDbService.database;

    await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  static Future<Event?> getById(String id) async {
    final db = await AppDbService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Event.fromMap(maps.first);
    }
    return null;
  }
}
