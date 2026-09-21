import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class UserRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  // ======================================
  // GET ALL USERS
  // ======================================

  Future<List<Map<String, dynamic>>> getAll() async {

    final db = await _db;

    return await db.rawQuery("""

SELECT

users.*,

section_master.sectionName,

beat_master.beatName

FROM users

LEFT JOIN section_master

ON users.sectionId = section_master.id

LEFT JOIN beat_master

ON users.beatId = beat_master.id

ORDER BY users.name

""");

  }

  // ======================================
  // GET ACTIVE USERS BY ROLE
  // ======================================

  Future<List<Map<String, dynamic>>> getUsersByRole(

    String role,

  ) async {

    final db = await _db;

    return await db.query(

      "users",

      where: "role=? AND isActive=1",

      whereArgs: [

        role,

      ],

      orderBy: "name",

    );

  }

  // ======================================
  // GET BFO BY BEAT
  // ======================================

  Future<Map<String, dynamic>?> getBFOByBeat(

    int beatId,

  ) async {

    final db = await _db;

    final result = await db.query(

      "users",

      where: "role=? AND beatId=? AND isActive=1",

      whereArgs: [

        "BFO",

        beatId,

      ],

      limit: 1,

    );

    if (result.isEmpty) {

      return null;

    }

    return result.first;

  }
  // ======================================
// LOGIN
// ======================================

Future<Map<String, dynamic>?> login({

  required String username,

  required String password,

}) async {

  // Stage 3: live cloud login when online.
  if (OnlineMode.enabled) {
    try {
      final rows = await OnlineDatabase.select(
        'users',
        equals: {
          'username': username,
          'password': password,
        },
        limit: 5,
      );
      for (final row in rows) {
        if ((row['isActive'] ?? 1) == 1) return row;
      }
      return null;
    } catch (e) {
      debugPrint('online login failed, falling back to local: $e');
    }
  }

  final db = await _db;

  final result = await db.query(

    "users",

    where:

        "username=? AND password=? AND isActive=1",

    whereArgs: [

      username,

      password,

    ],

    limit: 1,

  );

  if (result.isEmpty) {

    return null;

  }

  return result.first;

}
    // ======================================
  // INSERT USER
  // ======================================

  Future<void> insert({

    required String name,

    required String username,

    required String password,

    required String role,

    required int? sectionId,

    required int? beatId,

    required bool isActive,

  }) async {

    final db = await _db;

    await db.insert(

      "users",

      {

        "name": name,

        "username": username,

        "password": password,

        "role": role,

        "sectionId": sectionId,

        "beatId": beatId,

        "isActive": isActive ? 1 : 0,

      },

    );

  }

  // ======================================
  // UPDATE USER
  // ======================================

  Future<void> update({

    required int id,

    required String name,

    required String username,

    required String password,

    required String role,

    required int? sectionId,

    required int? beatId,

    required bool isActive,

  }) async {

    final db = await _db;

    await db.update(

      "users",

      {

        "name": name,

        "username": username,

        "password": password,

        "role": role,

        "sectionId": sectionId,

        "beatId": beatId,

        "isActive": isActive ? 1 : 0,

      },

      where: "id=?",

      whereArgs: [

        id,

      ],

    );

  }

  // ======================================
  // DELETE USER
  // ======================================

  Future<void> delete(

    int id,

  ) async {

    final db = await _db;

    await db.delete(

      "users",

      where: "id=?",

      whereArgs: [

        id,

      ],

    );

  }

}