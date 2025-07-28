import 'dart:math';
import 'package:sqflite/sqflite.dart';
import 'package:attendance_app/services/app_db_service.dart';
import 'package:attendance_app/features/event_organization/models/event_participant.dart';

class EventParticipantTableService {
  static const String table = 'event_participants';

  static Future<void> createTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS event_participants(
        id TEXT PRIMARY KEY,
        event_organization_id TEXT,
        individual_id TEXT,
        is_present INTEGER,
        FOREIGN KEY(event_organization_id) REFERENCES event_organizations(id) ON DELETE CASCADE
      )
    ''');
  }

  static Future<int> insert(EventParticipant participant) async {
    final db = await AppDbService.database;
    return await db.insert(
      table,
      participant.toMap()..remove('isHidden'),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<EventParticipant>> getByEventOrganizationId(
    String eventOrganizationId, {
    bool includeHidden = false,
    DateTime? eventDate,
  }) async {
    final db = await AppDbService.database;

    String query = '''
      SELECT ep.*, m.isHidden, m.hiddenAt
      FROM event_participants ep
      LEFT JOIN members m ON ep.individual_id = m.id
      WHERE ep.event_organization_id = ?
    ''';

    List<dynamic> args = [eventOrganizationId];

    if (!includeHidden) {
      query += '''
        AND (m.isHidden = 0 OR
            (m.isHidden = 1 AND (m.hiddenAt IS NULL OR m.hiddenAt > ?)))
      ''';
      args.add(
        eventDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      );
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery(query, args);

    return List.generate(maps.length, (i) {
      return EventParticipant.fromMap(maps[i]);
    });
  }

  static Future<int> update(EventParticipant participant) async {
    final db = await AppDbService.database;
    return await db.update(
      table,
      participant.toMap(),
      where: 'event_organization_id = ? AND individual_id = ?',
      whereArgs: [participant.eventOrganizationId, participant.individualId],
    );
  }

  static Future<int> delete(
    String eventOrganizationId,
    String individualId,
  ) async {
    final db = await AppDbService.database;
    return await db.delete(
      table,
      where: 'event_organization_id = ? AND individual_id = ?',
      whereArgs: [eventOrganizationId, individualId],
    );
  }

  static Future<void> seedForEventOrganization(
    String eventOrganizationId,
  ) async {
    final db = await AppDbService.database;
    final members = await db.query('members');
    if (members.isEmpty) return;

    final random = Random();
    final count = 2 + random.nextInt(4);
    final shuffled = List<Map<String, dynamic>>.from(members)..shuffle(random);
    final selected = shuffled.take(count);

    for (final member in selected) {
      final participant = EventParticipant(
        eventOrganizationId: eventOrganizationId,
        individualId: member['id'],
        isPresent: random.nextBool(),
      );
      await insert(participant);
    }
  }

  static Future<void> clear() async {
    final db = await AppDbService.database;
    await db.delete('event_participants');
  }

  static Future<bool> checkSchema(Database db) async {
    const expected = [
      {'name': 'id', 'type': 'TEXT'},
      {'name': 'event_organization_id', 'type': 'TEXT'},
      {'name': 'individual_id', 'type': 'TEXT'},
      {'name': 'is_present', 'type': 'INTEGER'},
    ];
    final info = await db.rawQuery("PRAGMA table_info(event_participants)");
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

  static Future<void> copyParticipantsFromPreviousEvent({
    required String newEventOrganizationId,
    required String eventId,
  }) async {
    final db = await AppDbService.database;

    try {
      final previousOrganizations = await db.query(
        'event_organizations',
        where: 'event_id = ? AND id != ?',
        whereArgs: [eventId, newEventOrganizationId],
        orderBy: 'date DESC',
      );

      final previousOrganizationId =
          previousOrganizations.first['id'] as String;

      final previousParticipants = await db.query(
        'event_participants',
        where: 'event_organization_id = ?',
        whereArgs: [previousOrganizationId],
      );

      for (final participant in previousParticipants) {
        final memberId = participant['individual_id'] as String;
        final member = await db.query(
          'members',
          where: 'id = ? AND isHidden = 0',
          whereArgs: [memberId],
          limit: 1,
        );

        if (member.isNotEmpty) {
          final newParticipant = EventParticipant(
            eventOrganizationId: newEventOrganizationId,
            individualId: memberId,
            isPresent: false,
          );
          await insert(newParticipant);
        }
      }
    } catch (e) {
      //
    }
  }
}
