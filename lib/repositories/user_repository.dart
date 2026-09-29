import '../services/user_mapping_rules.dart';
import '../services/session_service.dart';
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

  void _requireRfo() {
    if (SessionService.instance.role != 'RFO') throw StateError('Only RFO can manage users.');
  }
  Future<void> _validateUser({int? id, required String name, required String username,
    required String password, required String role, required int? sectionId,
    required int? beatId, required bool isActive}) async {
    _requireRfo();
    if (name.trim().isEmpty || username.trim().isEmpty || password.isEmpty) {
      throw ArgumentError('Enter name, login ID and password.');
    }
    if (!{'RFO','DRFO','BFO','Case Worker'}.contains(role)) throw ArgumentError('Select a valid role.');
    if ({'DRFO','BFO'}.contains(role) && sectionId == null) throw ArgumentError('Select a section.');
    if (role == 'BFO' && beatId == null) throw ArgumentError('Select a beat.');
    final rows = OnlineMode.enabled ? await OnlineDatabase.selectAll('users') : await (await _db).query('users');
    if (rows.any((u) => u['id'] != id && u['username'].toString().trim().toLowerCase() == username.trim().toLowerCase())) {
      throw StateError('That login ID already exists. Choose a different login ID.');
    }
    if (isActive && rows.any((u) => UserMappingRules.conflicts(u, id:id, role:role, sectionId:sectionId, beatId:beatId))) {
      throw StateError(role=='RFO' ? 'Only one active RFO login is allowed.' :
        role=='DRFO' ? 'This section already has an active DRFO. Edit or deactivate that user first.' :
        'This beat already has an active BFO. Edit or deactivate that user first.');
    }
    if (role == 'BFO') {
      final beats = OnlineMode.enabled ? await OnlineDatabase.select('beat_master', equals:{'id':beatId},limit:1)
          : await (await _db).query('beat_master',where:'id=?',whereArgs:[beatId]);
      if (beats.isEmpty || beats.first['sectionId'] != sectionId) throw ArgumentError('The selected beat must belong to the selected section.');
    }
    if (id == SessionService.instance.userId && (!isActive || role != 'RFO')) {
      throw StateError('The current RFO login must remain active with the RFO role. You can change its name, login ID and password.');
    }
  }

  // ======================================
  // GET ALL USERS
  // ======================================

  Future<List<Map<String, dynamic>>> getAll() async {

    if (OnlineMode.enabled) {
      try {
        final users = await OnlineDatabase.select(
          'users',
          orderBy: 'name',
        );
        final sections = await OnlineDatabase.select('section_master');
        final beats = await OnlineDatabase.select('beat_master');
        final sectionById = <int, Map<String, dynamic>>{
          for (final s in sections)
            if ((s['id'] as num?) != null)
              (s['id'] as num).toInt(): s,
        };
        final beatById = <int, Map<String, dynamic>>{
          for (final b in beats)
            if ((b['id'] as num?) != null)
              (b['id'] as num).toInt(): b,
        };
        final joined = [
          for (final u in users)
            {
              ...u,
              'sectionName': sectionById[(u['sectionId'] as num?)?.toInt()]?['sectionName'],
              'beatName': beatById[(u['beatId'] as num?)?.toInt()]?['beatName'],
            },
        ];
        joined.sort((a, b) => (a['name']?.toString() ?? '')
            .compareTo(b['name']?.toString() ?? ''));
        return joined;
      } catch (e) {
        rethrow;
      }
    }

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

    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          'users',
          equals: {'role': role, 'isActive': 1},
          orderBy: 'name',
        );
        rows.sort((a, b) => (a['name']?.toString() ?? '')
            .compareTo(b['name']?.toString() ?? ''));
        return rows;
      } catch (e) {
        rethrow;
      }
    }

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

  Future<Map<String,dynamic>?> getBFOByBeat(int beatId) async {
    return _singleMappedUser('BFO', 'beatId', beatId);
  }
  Future<Map<String,dynamic>?> getDRFOBySection(int sectionId) async {
    return _singleMappedUser('DRFO', 'sectionId', sectionId);
  }
  Future<Map<String,dynamic>?> _singleMappedUser(String role, String column, int id) async {
    final rows = OnlineMode.enabled
      ? await OnlineDatabase.select('users',equals:{'role':role,column:id,'isActive':1},limit:2)
      : await (await _db).query('users',where:'role=? AND $column=? AND isActive=1',whereArgs:[role,id],limit:2);
    if(rows.length>1) throw StateError('Multiple active $role users are mapped here. Correct User Master before forwarding.');
    return rows.isEmpty ? null : rows.first;
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
      debugPrint('Cloud login unavailable: $e');
      rethrow;
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
    await _validateUser(name: name, username: username, password: password,
      role: role, sectionId: sectionId, beatId: beatId, isActive: isActive);


    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.insert(
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
        return;
      } catch (e) {
        rethrow;
      }
    }

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
    await _validateUser(id: id, name: name, username: username, password: password,
      role: role, sectionId: sectionId, beatId: beatId, isActive: isActive);


    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.update(
          "users",
          id,
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
        return;
      } catch (e) {
        rethrow;
      }
    }

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
    _requireRfo();
    if (id == SessionService.instance.userId) throw StateError('You cannot delete the account currently logged in.');
    // Retain linked users for application ownership, assignments and historical names.
    bool linked = false;
    for (final column in ['createdBy','assignedBFO','assignedDRFO']) {
      final rows = OnlineMode.enabled
          ? await OnlineDatabase.select('applications', equals: {column: id}, limit: 1)
          : await (await _db).query('applications', where: '$column=?', whereArgs: [id], limit: 1);
      if (rows.isNotEmpty) { linked = true; break; }
    }
    if (linked) {
      if (OnlineMode.enabled) {
        await OnlineDatabase.update('users', id, {'isActive': 0});
      } else {
        await (await _db).update('users', {'isActive': 0}, where: 'id=?', whereArgs: [id]);
      }
      return;
    }


    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(
          "users",
          column: "id",
          value: id,
        );
        return;
      } catch (e) {
        rethrow;
      }
    }

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