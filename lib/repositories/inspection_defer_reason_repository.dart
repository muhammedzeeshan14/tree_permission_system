import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class InspectionDeferredReasonRepository {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => await dbHelper.database;

  Future<void> saveReasons({
    required int applicationId,
    required List<Map<String, dynamic>> reasons,
  }) async {
    final db = await _db;

    await db.delete(
      "inspection_deferred_reasons",
      where: "applicationId=?",
      whereArgs: [applicationId],
    );

    for (int i = 0; i < reasons.length; i++) {

  final master = await db.query(
    "master_data",
    where: "id=?",
    whereArgs: [reasons[i]["id"]],
    limit: 1,
  );

  String reasonName = "";

  if (master.isNotEmpty) {
    reasonName =
        master.first["value"]?.toString() ?? "";
  }

  await db.insert(
    "inspection_deferred_reasons",
    {
      "applicationId": applicationId,
      "reasonId": reasons[i]["id"],
      "reasonName": reasonName,
      "displayOrder": i + 1,
    },
  );
}
  }

  Future<List<int>> getReasonIds(
      int applicationId) async {
    final db = await _db;

    final rows = await db.query(
      "inspection_deferred_reasons",
      where: "applicationId=?",
      whereArgs: [applicationId],
      orderBy: "displayOrder",
    );

    return rows
        .map((e) => e["reasonId"] as int)
        .toList();
  }

  Future<List<Map<String, dynamic>>> getReasons(
    int applicationId) async {
  final db = await _db;

  return await db.rawQuery(
    '''
    SELECT
      saved.*,
      CASE
        WHEN TRIM(COALESCE(master.kannadaName, '')) <> ''
          THEN master.kannadaName
        ELSE saved.reasonName
      END AS documentReasonName
    FROM inspection_deferred_reasons AS saved
    LEFT JOIN master_data AS master
      ON master.id = saved.reasonId
    WHERE saved.applicationId = ?
    ORDER BY saved.displayOrder
    ''',
    [applicationId],
  );
}

  Future<void> deleteReasons(
      int applicationId) async {
    final db = await _db;

    await db.delete(
      "inspection_deferred_reasons",
      where: "applicationId=?",
      whereArgs: [applicationId],
    );
  }
}