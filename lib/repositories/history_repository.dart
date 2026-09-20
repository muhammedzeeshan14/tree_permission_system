import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

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

    final db = await _db;

    return await db.query(

      "application_history",

      where: "officeNumber=?",

      whereArgs: [officeNumber],

      orderBy: "id ASC",

    );

  }

}