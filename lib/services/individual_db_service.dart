import 'package:path/path.dart';
import 'package:faker/faker.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../features/individual/models/individual.dart';

class IndividualDbService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'individuals.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE individuals(
            id TEXT PRIMARY KEY,
            firstName TEXT,
            lastName TEXT,
            birthDate TEXT,
            isHidden INTEGER
          )
        ''');
      },
    );
  }

  static Future<void> clearDatabase() async {
    final db = await database;
    await db.delete('individuals');
  }

  static Future<void> seedDatabase({int count = 10}) async {
    final db = await database;
    final faker = Faker();

    for (int i = 0; i < count; i++) {
      final individual = Individual(
        id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
        firstName: faker.person.firstName(),
        lastName: faker.person.lastName(),
        birthDate: faker.date.dateTime(minYear: 1950, maxYear: 2010),
        isHidden: faker.randomGenerator.boolean(),
      );

      await db.insert('individuals', {
        'id': individual.id,
        'firstName': individual.firstName,
        'lastName': individual.lastName,
        'birthDate': individual.birthDate.toIso8601String(),
        'isHidden': individual.isHidden ? 1 : 0,
      });
    }
  }

  static Future<void> insertIndividual(Individual individual) async {
    final db = await database;
    await db.insert(
      'individuals',
      individual.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> updateIndividual(Individual individual) async {
    final db = await database;
    await db.update(
      'individuals',
      individual.toMap(),
      where: 'id = ?',
      whereArgs: [individual.id],
    );
  }

  static Future<void> deleteIndividual(String id) async {
    final db = await database;
    await db.delete('individuals', where: 'id = ?', whereArgs: [id]);
  }

  static Future<List<Individual>> getAllIndividuals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('individuals');
    return maps.map((map) => Individual.fromMap(map)).toList();
  }
}
