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
        // Mirror to local so reads work even before the
        // background sync uploads local rows (or when a later
        // read falls back offline). A mirror failure must never
        // break the already-successful cloud save.
        try {
          await _saveLocal(
            applicationId: applicationId,
            reasons: reasons,
          );
        } catch (_) {}
        return;
      } catch (e) {
        debugPrint('online saveReasons inspection_deferred_reasons failed, falling back to local: $e');
      }
    }
    final db = await _db;

    await _saveLocal(
      applicationId: applicationId,
      reasons: reasons,
      db: db,
    );
  }

  /// Local delete + insert shared by the online mirror and the
  /// offline path. Looks up display names from the local masters.
  Future<void> _saveLocal({
    required int applicationId,
    required List<Map<String, dynamic>> reasons,
    DatabaseExecutor? db,
  }) async {
    final database = db ?? await _db;

    await database.delete(
      "inspection_deferred_reasons",
      where: "applicationId=?",
      whereArgs: [applicationId],
    );

    for (int i = 0; i < reasons.length; i++) {

  final master = await database.query(
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

  await database.insert(
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
        // Empty cloud result falls through to local: reasons may
        // have been saved offline and not synced yet.
        if (rows.isNotEmpty) {
          return rows
              .map((e) => (e["reasonId"] as num?)?.toInt() ?? 0)
              .toList();
        }
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
      // Empty cloud result falls through to local: reasons may
      // have been saved offline and not synced yet.
      if (saved.isNotEmpty) {
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
      }
    } catch (e) {
      debugPrint('online getReasons inspection_deferred_reasons failed, falling back to local: $e');
    }
  }
  final db = await _db;

  return await _localReasons(db, applicationId);
}

  /// Local read shared by the offline path and the online
  /// empty-result fallback. Prefers the master Kannada name so
  /// letters print Kannada.
  Future<List<Map<String, dynamic>>> _localReasons(
    DatabaseExecutor db,
    int applicationId,
  ) async {
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
        // Also clear local: with the empty-result local fallback
        // above, stale local rows would otherwise resurface.
        try {
          final db = await _db;
          await db.delete(
            "inspection_deferred_reasons",
            where: "applicationId=?",
            whereArgs: [applicationId],
          );
        } catch (_) {}
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
