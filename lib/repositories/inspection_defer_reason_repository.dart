import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../services/deferred_reason_labels.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';
import '../services/supabase_service.dart';

class InspectionDeferredReasonRepository {
  final Database? databaseOverride;
  InspectionDeferredReasonRepository({this.databaseOverride});
  Future<Database> get _db async =>
      databaseOverride ?? await DatabaseHelper.instance.database;
  bool get _online => databaseOverride == null && OnlineMode.enabled;

  Future<void> saveReasons({
    required int applicationId,
    required List<Map<String, dynamic>> reasons,
  }) async {
    final ids = reasons
        .map((r) => ((r['reasonId'] ?? r['id']) as num?)?.toInt())
        .toList();
    if (ids.any((id) => id == null) || ids.toSet().length != ids.length) {
      throw StateError('Select valid, distinct deferred reasons.');
    }
    final masters = _online
        ? await OnlineDatabase.selectAll(
            'master_data',
            equals: {'masterType': 'Inspection Deferred Reason'},
          )
        : await (await _db).query(
            'master_data',
            where: 'masterType=?',
            whereArgs: ['Inspection Deferred Reason'],
          );
    final byId = {for (final m in masters) m['id']: m};
    // Validate BEFORE deleting saved rows; a saved row ID is not a master ID.
    if (ids.any((id) => !byId.containsKey(id))) {
      throw StateError(
        'A selected deferred reason is invalid. Please reselect it.',
      );
    }
    final rows = <Map<String, dynamic>>[
      for (var i = 0; i < ids.length; i++)
        {
          'applicationId': applicationId,
          'reasonId': ids[i],
          'reasonName': byId[ids[i]]!['value']?.toString() ?? '',
          'displayOrder': i + 1,
        },
    ];
    if (_online) {
      await OnlineDatabase.delete(
        'inspection_deferred_reasons',
        column: 'applicationId',
        value: applicationId,
      );
      if (rows.isNotEmpty) {
        final stamp = DateTime.now().toIso8601String();
        await SupabaseService.client!
            .from('inspection_deferred_reasons')
            .insert(rows.map((r) => {...r, 'updatedAt': stamp}).toList());
      }
      // Cloud failures are surfaced, never reported as a successful local-only save.
      try {
        await (await _db).transaction(
          (tx) => _replace(tx, applicationId, rows),
        );
      } catch (_) {}
    } else {
      await (await _db).transaction((tx) => _replace(tx, applicationId, rows));
    }
  }

  Future<void> _replace(
    DatabaseExecutor db,
    int applicationId,
    List<Map<String, dynamic>> rows,
  ) async {
    await db.delete(
      'inspection_deferred_reasons',
      where: 'applicationId=?',
      whereArgs: [applicationId],
    );
    for (final row in rows) {
      await db.insert('inspection_deferred_reasons', row);
    }
  }

  Future<List<int>> getReasonIds(int applicationId) async =>
      (await getReasons(applicationId))
          .where((r) => r['masterAvailable'] == true)
          .map((r) => (r['reasonId'] as num).toInt())
          .toList();

  Future<List<Map<String, dynamic>>> getReasons(int applicationId) async {
    if (_online) {
      final saved = await OnlineDatabase.selectAll(
        'inspection_deferred_reasons',
        equals: {'applicationId': applicationId},
        orderBy: 'displayOrder',
      );
      if (saved.isEmpty)
        return []; // An empty cloud result must not resurrect stale local selections.
      final masters = await OnlineDatabase.selectAll(
        'master_data',
        equals: {'masterType': 'Inspection Deferred Reason'},
      );
      return resolveDeferredReasons(saved, masters);
    }
    final db = await _db;
    return resolveDeferredReasons(
      await db.query(
        'inspection_deferred_reasons',
        where: 'applicationId=?',
        whereArgs: [applicationId],
        orderBy: 'displayOrder',
      ),
      await db.query(
        'master_data',
        where: 'masterType=?',
        whereArgs: ['Inspection Deferred Reason'],
      ),
    );
  }

  Future<void> deleteReasons(int applicationId) async {
    if (_online) {
      await OnlineDatabase.delete(
        'inspection_deferred_reasons',
        column: 'applicationId',
        value: applicationId,
      );
      try {
        await (await _db).delete(
          'inspection_deferred_reasons',
          where: 'applicationId=?',
          whereArgs: [applicationId],
        );
      } catch (_) {}
      return;
    }
    await (await _db).delete(
      'inspection_deferred_reasons',
      where: 'applicationId=?',
      whereArgs: [applicationId],
    );
  }
}
