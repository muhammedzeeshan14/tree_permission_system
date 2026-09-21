import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class InspectionDeferredReasonRepository {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => await dbHelper.database;

  Future<void> saveReasons({
    required int applicationId,
    required List<Map<String, dynamic>> reasons,
  }) async {
    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(
          "inspection_deferred_reasons",
          column: "applicationId",
          value: applicationId,
        );

        for (int i = 0; i < reasons.length; i++) {
          final master = await OnlineDatabase.select(
            "master_data",
            equals: {"id": reasons[i]["id"]},
            limit: 1,
          );

          String reasonName = "";

          if (master.isNotEmpty) {
            reasonName =
                master.first["value"]?.toString() ?? "";
          }

          await OnlineDatabase.insert(
            "inspection_deferred_reasons",
            {
              "applicationId": applicationId,
              "reasonId": reasons[i]["id"],
              "reasonName": reasonName,
              "displayOrder": i + 1,
            },
          );
        }
        return;
      } catch (e) {
        debugPrint('online saveReasons inspection_deferred_reasons failed, falling back to local: $e');
      }
    }
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
    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "inspection_deferred_reasons",
          equals: {"applicationId": applicationId},
          orderBy: "displayOrder",
        );
        rows.sort((a, b) => ((a['displayOrder'] as num?)?.toInt() ?? 0)
            .compareTo((b['displayOrder'] as num?)?.toInt() ?? 0));
        return rows
            .map((e) => (e["reasonId"] as num?)?.toInt() ?? 0)
            .toList();
      } catch (e) {
        debugPrint('online getReasonIds inspection_deferred_reasons failed, falling back to local: $e');
      }
    }
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
  if (OnlineMode.enabled) {
    try {
      final saved = await OnlineDatabase.select(
        "inspection_deferred_reasons",
        equals: {"applicationId": applicationId},
        orderBy: "displayOrder",
      );
      saved.sort((a, b) => ((a['displayOrder'] as num?)?.toInt() ?? 0)
          .compareTo((b['displayOrder'] as num?)?.toInt() ?? 0));
      final masters = await OnlineDatabase.select("master_data");
      final kannadaById = <int, String>{
        for (final m in masters)
          if ((m['id'] as num?) != null)
            (m['id'] as num).toInt():
                (m['kannadaName']?.toString() ?? ''),
      };
      return [
        for (final row in saved)
          {
            ...row,
            'documentReasonName': (() {
              final kannada = (kannadaById[(row['reasonId'] as num?)?.toInt()] ?? '').trim();
              if (kannada.isNotEmpty) return kannada;
              return row['reasonName']?.toString() ?? '';
            })(),
          },
      ];
    } catch (e) {
      debugPrint('online getReasons inspection_deferred_reasons failed, falling back to local: $e');
    }
  }
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
    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(
          "inspection_deferred_reasons",
          column: "applicationId",
          value: applicationId,
        );
        return;
      } catch (e) {
        debugPrint('online deleteReasons inspection_deferred_reasons failed, falling back to local: $e');
      }
    }
    final db = await _db;

    await db.delete(
      "inspection_deferred_reasons",
      where: "applicationId=?",
      whereArgs: [applicationId],
    );
  }
}
