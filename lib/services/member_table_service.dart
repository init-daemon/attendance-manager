import 'package:faker/faker.dart';
import 'package:sqflite/sqflite.dart';
import 'package:attendance_app/features/member/models/member.dart';
import 'package:attendance_app/services/app_db_service.dart';

class MemberTableService {
  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS members(
        id TEXT PRIMARY KEY,
        firstName TEXT,
        lastName TEXT,
        birthDate TEXT,
        isHidden INTEGER
      )
    ''');
  }

  static Future<void> clear() async {
    final db = await AppDbService.database;

    await db.delete('members');
  }

  static Future<void> seed({int count = 10}) async {
    final db = await AppDbService.database;
    final faker = Faker();
    for (int i = 0; i < count; i++) {
      final member = Member(
        id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
        firstName: faker.person.firstName(),
        lastName: faker.person.lastName(),
        birthDate: faker.date.dateTime(minYear: 1950, maxYear: 2010),
        isHidden: faker.randomGenerator.boolean(),
      );

      await db.insert('members', member.toMap());
    }
  }

  static Future<void> insert(Member member) async {
    final db = await AppDbService.database;

    await db.insert(
      'members',
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> update(Member member) async {
    final db = await AppDbService.database;

    await db.update(
      'members',
      member.toMap(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  static Future<void> delete(String id) async {
    final db = await AppDbService.database;

    await db.delete('members', where: 'id = ?', whereArgs: [id]);
  }

  static Future<bool> checkSchema(Database db) async {
    const expected = [
      {'name': 'id', 'type': 'TEXT'},
      {'name': 'firstName', 'type': 'TEXT'},
      {'name': 'lastName', 'type': 'TEXT'},
      {'name': 'birthDate', 'type': 'TEXT'},
      {'name': 'isHidden', 'type': 'INTEGER'},
    ];
    final info = await db.rawQuery("PRAGMA table_info(members)");
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
