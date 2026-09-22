import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class HistoryRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  // ======================================
  // ADD HISTORY
  // ======================================

  Future<void> addHistory({

    required String officeNumber,

    required String action,

    required String remarks,

    required String actionBy,

  }) async {

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.insert(
          "application_history",
          {
            "officeNumber": officeNumber,
            "action": action,
            "remarks": remarks,
            "actionBy": actionBy,
            "actionDate":
                DateTime.now().toIso8601String(),
          },
        );
        return;
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    await db.insert(

      "application_history",

      {

        "officeNumber": officeNumber,

        "action": action,

        "remarks": remarks,

        "actionBy": actionBy,

        "actionDate":
            DateTime.now().toIso8601String(),

      },

    );

  }

  // ======================================
  // GET HISTORY
  // ======================================

  Future<List<Map<String, dynamic>>> getHistory(

      String officeNumber) async {

    if (OnlineMode.enabled) {
      try {
        return await OnlineDatabase.select(
          "application_history",
          equals: {"officeNumber": officeNumber},
          orderBy: "id",
        );
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    return await db.query(

      "application_history",

      where: "officeNumber=?",

      whereArgs: [officeNumber],

      orderBy: "id ASC",

    );

  }

}