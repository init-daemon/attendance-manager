import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:attendance_app/services/member_table_service.dart';
import 'package:attendance_app/services/event_table_service.dart';
import 'package:attendance_app/services/event_organization_table_service.dart';
import 'package:attendance_app/services/event_participant_table_service.dart';

class DbService {
  static Future<void> initialize({
    bool fresh = true,
    bool onlyClear = true,
  }) async {
    if (fresh) {
      await _deleteDatabase();
    }

    await _createTables();

    if (onlyClear) {
      return;
    }

    await _initializeTable(
      tableName: 'members',
      clear: MemberTableService.clear,
      seed: (count) => MemberTableService.seed(count: count),
      fresh: fresh,
      seedCount: 100,
    );

    await _initializeTable(
      tableName: 'events',
      clear: EventTableService.clear,
      seed: (count) => EventTableService.seed(count: count),
      fresh: fresh,
      seedCount: 20,
    );

    await _initializeTable(
      tableName: 'event_organizations',
      clear: EventOrganizationTableService.clear,
      seed: (count) => EventOrganizationTableService.seed(count: count),
      fresh: fresh,
      seedCount: 200,
    );
  }

  static Future<void> _createTables() async {
    final db = await _getDatabase();
    await MemberTableService.createTable(db);
    await EventTableService.createTable(db);
    await EventOrganizationTableService.createTable(db);
    await EventParticipantTableService.createTable(db);
  }

  static Future<dynamic> getRandomRow({
    required String tableName,
    bool returnIdOnly = false,
  }) async {
    final db = await _getDatabase();

    try {
      final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT * FROM $tableName ORDER BY RANDOM() LIMIT 1',
      );

      if (result.isEmpty) return null;

      return returnIdOnly ? result.first['id'] : result.first;
    } catch (e) {
      print('Error getting random row from $tableName: $e');
      return null;
    }
  }

  static Future<void> _deleteDatabase() async {
    final dbPath = await getDatabasesPath();
    final appDb = File(join(dbPath, 'app.db'));
    if (await appDb.exists()) {
      await appDb.delete();
    }
  }

  static Future<void> _initializeTable({
    required String tableName,
    required Future<void> Function() clear,
    required Future<void> Function(int) seed,
    required bool fresh,
    required int seedCount,
  }) async {
    final db = await _getDatabase();
    final List<Map<String, dynamic>> items = await db.query(
      tableName,
      limit: 1,
    );

    if (fresh || items.isEmpty) {
      if (!fresh) {
        await clear();
      }
      await seed(seedCount);
    }
  }

  static Future<Database> getDatabase() async {
    return await _getDatabase();
  }

  static Future<Database> _getDatabase() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'app.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('PRAGMA foreign_keys = ON;');
        await MemberTableService.createTable(db);
        await EventTableService.createTable(db);
        await EventOrganizationTableService.createTable(db);
        await EventParticipantTableService.createTable(db);
      },
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;');
        await MemberTableService.createTable(db);
        await EventTableService.createTable(db);
        await EventOrganizationTableService.createTable(db);
        await EventParticipantTableService.createTable(db);
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getPaged({
    required String tableName,
    required int limit,
    required int offset,
    String? orderBy,
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await _getDatabase();
    return await db.query(
      tableName,
      limit: limit,
      offset: offset,
      orderBy: orderBy,
      where: where,
      whereArgs: whereArgs,
    );
  }

  static Future<int> count(
    String tableName, {
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await _getDatabase();
    final result = where == null
        ? await db.rawQuery('SELECT COUNT(*) as count FROM $tableName')
        : await db.rawQuery(
            'SELECT COUNT(*) as count FROM $tableName WHERE $where',
            whereArgs,
          );
    return result.first['count'] as int? ?? 0;
  }

  static Future<List<Map<String, dynamic>>> search({
    required String tableName,
    required String query,
    required List<String> fields,
    int limit = 20,
    int offset = 0,
    String? orderBy,
    String? where,
    List<dynamic>? whereArgs,
  }) async {
    final db = await _getDatabase();
    final trimmedQuery = query.trim();

    final searchConditions = fields
        .map((field) => '$field LIKE ?')
        .join(' OR ');
    final searchArgs = fields.map((_) => '%$trimmedQuery%').toList();

    String finalWhere;
    List<dynamic> finalArgs;

    if (where != null) {
      finalWhere = '($searchConditions) AND ($where)';
      finalArgs = [...searchArgs, ...?whereArgs];
    } else {
      finalWhere = searchConditions;
      finalArgs = searchArgs;
    }

    return await db.query(
      tableName,
      where: finalWhere,
      whereArgs: finalArgs,
      limit: limit,
      offset: offset,
      orderBy: orderBy,
    );
  }

  static Future<List<Map<String, dynamic>>> getByField({
    required String tableName,
    required String field,
    required dynamic value,
  }) async {
    final db = await _getDatabase();
    return await db.query(tableName, where: '$field = ?', whereArgs: [value]);
  }

  static Future<void> deleteById({
    required String tableName,
    required dynamic id,
  }) async {
    final db = await _getDatabase();
    await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  static Future<String> getDatabasePath() async {
    return join(await getDatabasesPath(), 'app.db');
  }
}
