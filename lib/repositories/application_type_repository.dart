import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class ApplicationTypeRepository {

  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => await dbHelper.database;

  Future<List<Map<String, dynamic>>> getAll() async {

    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "application_type_master",
          orderBy: "displayOrder",
        );
        rows.sort((a, b) => ((a['displayOrder'] as num?)?.toInt() ?? 0)
            .compareTo((b['displayOrder'] as num?)?.toInt() ?? 0));
        return rows;
      } catch (e) {
        debugPrint('online getAll application_type_master failed, falling back to local: $e');
      }
    }

    final db = await _db;

    return await db.query(
      "application_type_master",
      orderBy: "displayOrder ASC",
    );

  }

  Future<List<Map<String, dynamic>>> getActive() async {

    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "application_type_master",
          equals: {"isActive": 1},
          orderBy: "displayOrder",
        );
        rows.sort((a, b) => ((a['displayOrder'] as num?)?.toInt() ?? 0)
            .compareTo((b['displayOrder'] as num?)?.toInt() ?? 0));
        return rows;
      } catch (e) {
        debugPrint('online getActive application_type_master failed, falling back to local: $e');
      }
    }

    final db = await _db;

    return await db.query(
      "application_type_master",
      where: "isActive=?",
      whereArgs: [1],
      orderBy: "displayOrder ASC",
    );

  }

  Future<void> insert({

  required String applicationType,

  required String kannadaName,

  required String shortCode,

  required int displayOrder,

  required bool isActive,

}) async {

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.insert(
          "application_type_master",
          {
            "applicationType": applicationType,
            "kannadaName": kannadaName,
            "shortCode": shortCode,
            "displayOrder": displayOrder,
            "isActive": isActive ? 1 : 0,
          },
        );
        return;
      } catch (e) {
        debugPrint('online insert application_type_master failed, falling back to local: $e');
      }
    }

    final db = await _db;

    await db.insert(
      "application_type_master",
      {

        "applicationType": applicationType,

        "kannadaName": kannadaName,

        "shortCode": shortCode,

        "displayOrder": displayOrder,

        "isActive": isActive ? 1 : 0,

      },

    );

  }

  Future<void> update({

  required int id,

  required String applicationType,

  required String kannadaName,

  required String shortCode,

  required int displayOrder,

  required bool isActive,

}) async {

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.update(
          "application_type_master",
          id,
          {
            "applicationType": applicationType,
            "kannadaName": kannadaName,
            "shortCode": shortCode,
            "displayOrder": displayOrder,
            "isActive": isActive ? 1 : 0,
          },
        );
        return;
      } catch (e) {
        debugPrint('online update application_type_master failed, falling back to local: $e');
      }
    }

    final db = await _db;

    await db.update(

      "application_type_master",

      {

        "applicationType": applicationType,

        "kannadaName": kannadaName,

        "shortCode": shortCode,

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
          "application_type_master",
          column: "id",
          value: id,
        );
        return;
      } catch (e) {
        debugPrint('online delete application_type_master failed, falling back to local: $e');
      }
    }

    final db = await _db;

    await db.delete(

      "application_type_master",

      where: "id=?",

      whereArgs: [id],

    );

  }

}
