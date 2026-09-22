import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

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
    if (OnlineMode.enabled) {
      try {
        final row = {
          "applicationId": applicationId,
          "itemKey": itemKey,
          "itemId": itemId,
          "decision": decision,
          "reason": decision == "Re-inspect" ? reason : null,
          "approvedBy": approvedBy,
          "approvedDate": DateTime.now().toIso8601String(),
        };
        final existing = await OnlineDatabase.select(
          "rfo_item_approvals",
          equals: {
            "applicationId": applicationId,
            "itemKey": itemKey,
            "itemId": itemId,
          },
          limit: 1,
        );
        if (existing.isEmpty) {
          await OnlineDatabase.insert("rfo_item_approvals", row);
        } else {
          await OnlineDatabase.update(
            "rfo_item_approvals",
            (existing.first["id"] as num).toInt(),
            row,
          );
        }
        return;
      } catch (e) {
        debugPrint('online saveDecision rfo_item_approvals failed, falling back to local: $e');
      }
    }
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
    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "rfo_item_approvals",
          equals: {
            "applicationId": applicationId,
            "itemKey": itemKey,
            "itemId": itemId,
          },
          limit: 1,
        );
        if (rows.isEmpty) return null;
        return rows.first;
      } catch (e) {
        debugPrint('online getDecision rfo_item_approvals failed, falling back to local: $e');
      }
    }
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
    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "rfo_item_approvals",
          equals: {"applicationId": applicationId},
        );
        rows.sort((a, b) {
          final key = (a["itemKey"]?.toString() ?? "")
              .compareTo(b["itemKey"]?.toString() ?? "");
          if (key != 0) return key;
          return (((a["itemId"] as num?)?.toInt() ?? 0))
              .compareTo((b["itemId"] as num?)?.toInt() ?? 0);
        });
        return rows;
      } catch (e) {
        debugPrint('online getApplicationDecisions rfo_item_approvals failed, falling back to local: $e');
      }
    }
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
    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "rfo_item_approvals",
          equals: {"applicationId": applicationId},
        );
        return rows.any((row) =>
            (row["decision"]?.toString() ?? "").trim().toUpperCase() ==
            'RE-INSPECT');
      } catch (e) {
        debugPrint('online hasReinspection rfo_item_approvals failed, falling back to local: $e');
      }
    }
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
    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(
          "rfo_item_approvals",
          column: "applicationId",
          value: applicationId,
        );
        return;
      } catch (e) {
        debugPrint('online clearApplicationDecisions rfo_item_approvals failed, falling back to local: $e');
      }
    }
    final db = await _db;

    await db.delete(
      "rfo_item_approvals",
      where: "applicationId = ?",
      whereArgs: [applicationId],
    );
  }
}