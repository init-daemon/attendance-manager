import 'package:faker/faker.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:attendance_app/features/member/models/member.dart';
import 'package:attendance_app/services/app_db_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'dart:math';

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
    final random = Random();

    for (int i = 0; i < count; i++) {
      final hasBirthDate = random.nextDouble() < 0.8;

      final member = Member(
        id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
        firstName: faker.person.firstName(),
        lastName: faker.person.lastName(),
        birthDate: hasBirthDate
            ? faker.date.dateTime(minYear: 1950, maxYear: 2010)
            : null,
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

  static Future<Map<String, dynamic>> importMembersFromExcel() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null) {
        return {'success': false, 'message': 'Import annulé', 'duplicates': []};
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        return {
          'success': false,
          'message': 'Accès au fichier refusé',
          'duplicates': [],
        };
      }

      final file = File(filePath);
      if (!await file.exists()) {
        return {
          'success': false,
          'message': 'Fichier introuvable',
          'duplicates': [],
        };
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return {'success': false, 'message': 'Fichier vide', 'duplicates': []};
      }

      Excel excel;
      try {
        excel = Excel.decodeBytes(bytes);
      } catch (e) {
        return {
          'success': false,
          'message': 'Format de fichier Excel invalide',
          'duplicates': [],
        };
      }

      if (excel.tables.isEmpty) {
        return {
          'success': false,
          'message': 'Aucune feuille trouvée',
          'duplicates': [],
        };
      }

      final sheet = excel.tables.values.first;
      final db = await AppDbService.database;
      List<Map<String, dynamic>> duplicates = [];
      int importedCount = 0;

      for (var i = 0; i < sheet.rows.length; i++) {
        try {
          final row = sheet.rows[i];
          if (row.length < 2) continue;

          final lastName = row[0]?.value?.toString().trim() ?? '';
          final firstName = row[1]?.value?.toString().trim() ?? '';

          if (lastName.isEmpty || firstName.isEmpty) continue;

          final existing = await db.query(
            'members',
            where: 'lastName = ? AND firstName = ?',
            whereArgs: [lastName, firstName],
          );

          if (existing.isNotEmpty) {
            duplicates.add({'lastName': lastName, 'firstName': firstName});
            continue;
          }

          DateTime? birthDate;
          if (row.length >= 3) {
            final dateValue = row[2]?.value;
            if (dateValue is String) {
              birthDate = DateTime.tryParse(dateValue);
            } else if (dateValue is DateTime) {
              birthDate = dateValue;
            }
          }

          await db.insert(
            'members',
            Member(
              id: '${DateTime.now().millisecondsSinceEpoch}_$i',
              firstName: firstName,
              lastName: lastName,
              birthDate: birthDate,
              isHidden: false,
            ).toMap(),
          );

          importedCount++;
        } catch (e) {
          debugPrint('Erreur ligne ${i + 1}: $e');
        }
      }

      return {
        'success': true,
        'message': 'Succès: $importedCount membres importés',
        'duplicates': duplicates,
      };
    } catch (e) {
      debugPrint('Erreur d\'import: $e');
      return {
        'success': false,
        'message': 'Erreur technique: ${e.toString()}',
        'duplicates': [],
      };
    }
  }

  static Future<List<Member>> getAllMembers() async {
    final db = await AppDbService.database;
    final List<Map<String, dynamic>> maps = await db.query('members');
    return List.generate(maps.length, (i) {
      return Member.fromMap(maps[i]);
    });
  }
}
