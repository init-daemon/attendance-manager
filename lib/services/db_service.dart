import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:presence_manager/services/member_table_service.dart';
import 'package:presence_manager/services/event_table_service.dart';

class DbService {
  static Future<void> initialize({bool fresh = false}) async {
    if (fresh) {
      final dbPath = await getDatabasesPath();
      final appDb = File(join(dbPath, 'app.db'));
      if (await appDb.exists()) {
        await appDb.delete();
      }
    }

    final members = await MemberTableService.getAll();
    if (fresh || members.isEmpty) {
      if (!fresh) {
        await MemberTableService.clear();
      }
      await MemberTableService.seed(count: 10);
    }

    final events = await EventTableService.getAll();
    if (fresh || events.isEmpty) {
      if (!fresh) {
        await EventTableService.clear();
      }
      await EventTableService.seed(count: 10);
    }
  }
}
