import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:presence_manager/services/member_table_service.dart';
import 'package:presence_manager/services/event_table_service.dart';
import 'package:presence_manager/services/event_organization_table_service.dart';

class DbService {
  static Future<void> initialize({bool fresh = false}) async {
    if (fresh) {
      await _deleteDatabase();
    }

    await _initializeTable(
      getAll: MemberTableService.getAll,
      clear: MemberTableService.clear,
      seed: (count) => MemberTableService.seed(count: count),
      fresh: fresh,
      seedCount: 10,
    );

    await _initializeTable(
      getAll: EventTableService.getAll,
      clear: EventTableService.clear,
      seed: (count) => EventTableService.seed(count: count),
      fresh: fresh,
      seedCount: 10,
    );

    await _initializeTable(
      getAll: EventOrganizationTableService.getAll,
      clear: EventOrganizationTableService.clear,
      seed: (count) => EventOrganizationTableService.seed(count: count),
      fresh: fresh,
      seedCount: 5,
    );
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
    required Future<List<dynamic>> Function() getAll,
    required Future<void> Function() clear,
    required Future<void> Function(int) seed,
    required bool fresh,
    required int seedCount,
  }) async {
    final items = await getAll();

    if (fresh || items.isEmpty) {
      if (!fresh) {
        await clear();
      }
      await seed(seedCount);
    }
  }

  static Future<Database> _getDatabase() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'app.db'),
      version: 1,
    );
  }
}
