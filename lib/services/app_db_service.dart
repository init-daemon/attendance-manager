import 'package:path/path.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'member_table_service.dart';
import 'event_table_service.dart';

class AppDbService {
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
    final path = join(dbPath, 'app.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await MemberTableService.createTable(db);
        await EventTableService.createTable(db);
      },
    );
  }
}
