import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class TreeVerificationRepository {
  final dbHelper = DatabaseHelper.instance;

  Future<void> saveVerification({
  required int treeId,
  required String verification,
  String? verificationReason,
}) async {
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

Future<bool> hasModifiedTreeForApplication(
  int applicationId,
) async {
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