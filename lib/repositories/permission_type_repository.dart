import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class PermissionTypeRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<List<Map<String, dynamic>>> getAll() async {

    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "permission_type_master",
          orderBy: "displayOrder",
        );
        rows.sort((a, b) => ((a['displayOrder'] as num?)?.toInt() ?? 0)
            .compareTo((b['displayOrder'] as num?)?.toInt() ?? 0));
        return rows;
      } catch (e) {
        debugPrint('online getAll permission_type_master failed, falling back to local: $e');
      }
    }

    final db = await _db;

    return await db.query(

      "permission_type_master",

      orderBy: "displayOrder",

    );

  }

  Future<List<Map<String, dynamic>>> getActive() async {

    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "permission_type_master",
          equals: {"isActive": 1},
          orderBy: "displayOrder",
        );
        rows.sort((a, b) => ((a['displayOrder'] as num?)?.toInt() ?? 0)
            .compareTo((b['displayOrder'] as num?)?.toInt() ?? 0));
        return rows;
      } catch (e) {
        debugPrint('online getActive permission_type_master failed, falling back to local: $e');
      }
    }

    final db = await _db;

    return await db.query(

      "permission_type_master",

      where: "isActive=1",

      orderBy: "displayOrder",

    );

  }

  Future<void> insert({

    required String permissionType,

    required int displayOrder,

    required bool isActive,

  }) async {

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.insert(
          "permission_type_master",
          {
            "permissionType": permissionType,
            "displayOrder": displayOrder,
            "isActive": isActive ? 1 : 0,
          },
        );
        return;
      } catch (e) {
        debugPrint('online insert permission_type_master failed, falling back to local: $e');
      }
    }

    final db = await _db;

    await db.insert(

      "permission_type_master",

      {

        "permissionType": permissionType,

        "displayOrder": displayOrder,

        "isActive": isActive ? 1 : 0,

      },

    );

  }

  Future<void> update({

    required int id,

    required String permissionType,

    required int displayOrder,

    required bool isActive,

  }) async {

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.update(
          "permission_type_master",
          id,
          {
            "permissionType": permissionType,
            "displayOrder": displayOrder,
            "isActive": isActive ? 1 : 0,
          },
        );
        return;
      } catch (e) {
        debugPrint('online update permission_type_master failed, falling back to local: $e');
      }
    }

    final db = await _db;

    await db.update(

      "permission_type_master",

      {

        "permissionType": permissionType,

        "displayOrder": displayOrder,

        "isActive": isActive ? 1 : 0,

      },

      where: "id=?",

      whereArgs: [id],

    );

  }

  Future<void> delete(int id) async {

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(
          "permission_type_master",
          column: "id",
          value: id,
        );
        return;
      } catch (e) {
        debugPrint('online delete permission_type_master failed, falling back to local: $e');
      }
    }

    final db = await _db;

    await db.delete(

      "permission_type_master",

      where: "id=?",

      whereArgs: [id],

    );

  }

}
