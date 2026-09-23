import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class TreeVerificationRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<void> saveVerification({
  required int treeId,
  required String verification,
  String? verificationReason,
}) async {
    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(
          "tree_verifications",
          column: "treeId",
          value: treeId,
        );
        await OnlineDatabase.insert(
          "tree_verifications",
          {
            "treeId": treeId,
            "verification": verification,
            "verificationReason": verificationReason,
          },
        );
        return;
      } catch (_) {
        /* fall through to local */
      }
    }
    final db = await dbHelper.database;

    await db.insert(
      "tree_verifications",
      {
        "treeId": treeId,
  "verification": verification,
  "verificationReason": verificationReason,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getVerification(
    int treeId,
  ) async {
    if (OnlineMode.enabled) {
      try {
        final result = await OnlineDatabase.select(
          "tree_verifications",
          equals: {"treeId": treeId},
          limit: 1,
        );
        if (result.isEmpty) {
          return null;
        }
        return result.first["verification"] as String?;
      } catch (_) {
        /* fall through to local */
      }
    }
    final db = await dbHelper.database;

    final result = await db.query(
      "tree_verifications",
      where: "treeId=?",
      whereArgs: [treeId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first["verification"] as String?;
  }

  Future<String?> getVerificationReason(
    int treeId,
  ) async {
    if (OnlineMode.enabled) {
      try {
        final result = await OnlineDatabase.select(
          "tree_verifications",
          equals: {"treeId": treeId},
          limit: 1,
        );
        if (result.isEmpty) {
          return null;
        }
        return result.first["verificationReason"]?.toString();
      } catch (_) {
        /* fall through to local */
      }
    }
    final db = await dbHelper.database;

    final result = await db.query(
      "tree_verifications",
      where: "treeId=?",
      whereArgs: [treeId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first["verificationReason"]?.toString();
  }

Future<bool> hasModifiedTreeForApplication(
  int applicationId,
) async {
  if (OnlineMode.enabled) {
    try {
      final trees = await OnlineDatabase.select(
        'trees',
        equals: {'applicationId': applicationId},
      );
      if (trees.isEmpty) return false;
      final treeIds = <int>{
        for (final t in trees)
          if ((t['id'] as num?)?.toInt() != null)
            (t['id'] as num).toInt(),
      };
      final verifications = await OnlineDatabase.select(
        'tree_verifications',
      );
      return verifications.any((tv) {
        final treeId = (tv['treeId'] as num?)?.toInt();
        return treeId != null &&
            treeIds.contains(treeId) &&
            (tv['verification']?.toString() ?? '')
                    .trim()
                    .toUpperCase() ==
                'MODIFY';
      });
    } catch (_) {
      /* fall through to local */
    }
  }
  final db = await dbHelper.database;

  final result = await db.rawQuery(
    '''
    SELECT COUNT(*) AS modifiedCount
    FROM tree_verifications tv
    INNER JOIN trees t
      ON t.id = tv.treeId
    WHERE t.applicationId = ?
      AND UPPER(TRIM(tv.verification)) = 'MODIFY'
    ''',
    [applicationId],
  );

  final modifiedCount =
      Sqflite.firstIntValue(result) ?? 0;

  return modifiedCount > 0;
}

}