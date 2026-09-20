import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class RfoItemApprovalRepository {
  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<void> saveDecision({
    required int applicationId,
    required String itemKey,
    int itemId = 0,
    required String decision,
    String? reason,
    required String approvedBy,
  }) async {
    final db = await _db;

    await db.insert(
      "rfo_item_approvals",
      {
        "applicationId": applicationId,
        "itemKey": itemKey,
        "itemId": itemId,
        "decision": decision,
        "reason":
            decision == "Re-inspect"
                ? reason
                : null,
        "approvedBy": approvedBy,
        "approvedDate":
            DateTime.now().toIso8601String(),
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getDecision({
    required int applicationId,
    required String itemKey,
    int itemId = 0,
  }) async {
    final db = await _db;

    final result = await db.query(
      "rfo_item_approvals",
      where:
          "applicationId = ? AND itemKey = ? AND itemId = ?",
      whereArgs: [
        applicationId,
        itemKey,
        itemId,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<List<Map<String, dynamic>>>
      getApplicationDecisions(
    int applicationId,
  ) async {
    final db = await _db;

    return db.query(
      "rfo_item_approvals",
      where: "applicationId = ?",
      whereArgs: [applicationId],
      orderBy: "itemKey, itemId",
    );
  }

  Future<bool> hasReinspection(
    int applicationId,
  ) async {
    final db = await _db;

    final result = await db.rawQuery(
      """
      SELECT COUNT(*) AS count
      FROM rfo_item_approvals
      WHERE applicationId = ?
        AND UPPER(TRIM(decision)) = 'RE-INSPECT'
      """,
      [applicationId],
    );

    return (Sqflite.firstIntValue(result) ?? 0) >
        0;
  }

  Future<void> clearApplicationDecisions(
    int applicationId,
  ) async {
    final db = await _db;

    await db.delete(
      "rfo_item_approvals",
      where: "applicationId = ?",
      whereArgs: [applicationId],
    );
  }
}