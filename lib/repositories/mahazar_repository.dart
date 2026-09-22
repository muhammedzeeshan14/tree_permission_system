import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/mahazar_model.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class MahazarRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<void> save(
      MahazarModel item) async {

    if (OnlineMode.enabled) {
      try {
        final existing = await OnlineDatabase.select(
          "application_mahazar",
          equals: {"applicationId": item.applicationId},
          limit: 1,
        );
        if (existing.isEmpty) {
          await OnlineDatabase.insert(
            "application_mahazar",
            item.toMap(),
          );
        } else {
          await OnlineDatabase.delete(
            "application_mahazar",
            column: "applicationId",
            value: item.applicationId,
          );
          await OnlineDatabase.insert(
            "application_mahazar",
            item.toMap(),
          );
        }
        return;
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    await db.delete(

      "application_mahazar",

      where: "applicationId=?",

      whereArgs: [item.applicationId],

    );

    await db.insert(

      "application_mahazar",

      item.toMap(),

    );

  }

  Future<MahazarModel?> getByApplication(
      int applicationId) async {

    if (OnlineMode.enabled) {
      try {
        final result = await OnlineDatabase.select(
          "application_mahazar",
          equals: {"applicationId": applicationId},
          limit: 1,
        );
        if (result.isEmpty) {
          return null;
        }
        return MahazarModel.fromMap(
          result.first,
        );
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    final result = await db.query(

      "application_mahazar",

      where: "applicationId=?",

      whereArgs: [applicationId],

      limit: 1,

    );

    if (result.isEmpty) {

      return null;

    }

    return MahazarModel.fromMap(
      result.first,
    );

  }

}