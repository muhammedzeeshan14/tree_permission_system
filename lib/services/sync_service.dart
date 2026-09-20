import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../database/database_helper.dart';
import 'connectivity_service.dart';
import 'supabase_service.dart';

/// Stage 2: real offline-first push/pull.
///
/// - Local sqflite stays the cache; every mutation calls [markDirty].
/// - [syncNow] pushes queued rows (last-write-wins via `updatedAt`)
///   then pulls rows changed since last sync.
/// - Integer PK limitation: two devices creating rows with the same
///   local id will collide on upsert. Keep creation on one device
///   per workflow (e.g. Case Worker creates) until UUID migration
///   in Stage 3. Updates to existing rows are safe.
class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  static const _lastSyncKey = 'tpms_last_sync_iso';

  /// Tables pushed AND pulled in Stage 2, in dependency order.
  /// Masters are pulled; app rows are pushed then pulled.
  static const List<String> syncedTables = [
    'users',
    'section_master',
    'beat_master',
    'application_type_master',
    'permission_type_master',
    'forwarded_source_master',
    'revenue_opinion_master',
    'applications',
    'trees',
    'application_verifications',
    'application_forward_references',
    'application_tree_count_site',
    'application_tree_count',
    'application_mahazar',
    'inspection_photos',
    'inspection_documents',
    'rfo_item_approvals',
    'application_revenue_opinion',
    'revenue_reply_cycles',
    'application_history',
  ];

  Future<void> markDirty({
    required String tableName,
    required int localId,
    String operation = 'upsert',
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(
        'sync_queue',
        {
          'tableName': tableName,
          'localId': localId,
          'operation': operation,
          'createdAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('markDirty failed: $e');
    }
  }

  Future<int> pendingCount() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM sync_queue',
      );
      if (result.isEmpty) return 0;
      return (result.first['c'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<DateTime?> lastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncKey);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> _touchSync() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _lastSyncKey,
      DateTime.now().toIso8601String(),
    );
  }

  Future<String> syncNow() async {
    if (!ConnectivityService.instance.isOnline) {
      return 'Offline — ${await pendingCount()} change(s) queued locally.';
    }
    final client = SupabaseService.client;
    if (client == null) {
      return 'Supabase not configured — ${await pendingCount()} change(s) queued locally.';
    }
    final since = await lastSync();
    int pushed = 0;
    int pulled = 0;
    final errors = <String>[];
    try {
      final result = await _pushQueue(client);
      pushed = result.pushed;
      if (result.firstError != null) {
        errors.add('push: ${result.firstError}');
      }
    } catch (e) {
      errors.add('push: $e');
    }
    try {
      pulled = await _pullSince(client, since);
    } catch (e) {
      errors.add('pull: $e');
    }
    if (errors.isEmpty) {
      await _touchSync();
    }
    final pending = await pendingCount();
    final msg =
        'Pushed $pushed, pulled $pulled, $pending queued.'
        '${errors.isEmpty ? '' : ' Errors: ${errors.join('; ')}'}';
    debugPrint('Sync: $msg');
    return msg;
  }

  Future<_PushResult> _pushQueue(SupabaseClient client) async {
    final db = await DatabaseHelper.instance.database;
    final queue = await db.query('sync_queue', orderBy: 'id ASC', limit: 200);
    int ok = 0;
    String? firstError;
    for (final entry in queue) {
      final qid = entry['id'] as int;
      final table = entry['tableName']?.toString() ?? '';
      final localId = (entry['localId'] as int?) ?? 0;
      final op = entry['operation']?.toString() ?? 'upsert';
      try {
        if (!syncedTables.contains(table)) {
          await db.delete('sync_queue', where: 'id=?', whereArgs: [qid]);
          continue;
        }
        if (op == 'delete') {
          await client.from(table).delete().eq('id', localId);
        } else {
          final rows = await db.query(
            table,
            where: 'id=?',
            whereArgs: [localId],
            limit: 1,
          );
          if (rows.isEmpty) {
            await db.delete('sync_queue', where: 'id=?', whereArgs: [qid]);
            continue;
          }
          final payload = _toRemote(table, rows.first);
          await client.from(table).upsert(payload, onConflict: 'id');
        }
        await db.delete('sync_queue', where: 'id=?', whereArgs: [qid]);
        ok++;
      } catch (e) {
        firstError ??= '$table#$localId: $e';
        debugPrint('push $table#$localId failed: $e');
        // Keep entry queued for next run.
      }
    }
    return _PushResult(ok, firstError);
  }

  Future<int> _pullSince(SupabaseClient client, DateTime? since) async {
    final db = await DatabaseHelper.instance.database;
    int total = 0;
    for (final table in syncedTables) {
      try {
        final hasUpdatedAt = await _hasColumn(db, table, 'updatedAt');
        var query = client.from(table).select();
        if (since != null && hasUpdatedAt) {
          query = query.gte(
            'updatedAt',
            since.toUtc().toIso8601String(),
          );
        }
        final rows = await query.limit(500);
        final list = (rows as List).cast<Map<String, dynamic>>();
        for (final remote in list) {
          final local = _toLocal(remote);
          final id = _asInt(local['id']);
          if (id == null) continue;
          final existing = await db.query(
            table,
            where: 'id=?',
            whereArgs: [id],
            limit: 1,
          );
          if (existing.isEmpty) {
            await db.insert(
              table,
              local,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } else if (_isRemoteNewer(local, existing.first)) {
            await db.update(
              table,
              local,
              where: 'id=?',
              whereArgs: [id],
            );
          }
          total++;
        }
      } catch (e) {
        debugPrint('pull $table failed: $e');
      }
    }
    return total;
  }

  /// Drop nulls and local-only helpers; stamp updatedAt.
  Map<String, dynamic> _toRemote(
    String table,
    Map<String, dynamic> local,
  ) {
    final out = Map<String, dynamic>.from(local);
    out['updatedAt'] ??= DateTime.now().toIso8601String();
    return out;
  }

  Map<String, Object?> _toLocal(Map<String, dynamic> remote) {
    final out = <String, Object?>{};
    remote.forEach((key, value) {
      if (value == null) {
        out[key] = null;
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  bool _isRemoteNewer(
    Map<String, Object?> remote,
    Map<String, Object?> local,
  ) {
    final r = DateTime.tryParse(remote['updatedAt']?.toString() ?? '');
    final l = DateTime.tryParse(local['updatedAt']?.toString() ?? '');
    if (r == null) return false;
    if (l == null) return true;
    return r.isAfter(l);
  }

  Future<bool> _hasColumn(
    Database db,
    String table,
    String column,
  ) async {
    try {
      final cols = await db.rawQuery('PRAGMA table_info($table)');
      return cols.any((c) => c['name']?.toString() == column);
    } catch (_) {
      return false;
    }
  }

  /// Helper for repositories: stamp a row map with sync metadata.
  static Map<String, Object?> withSyncStamp(
    Map<String, Object?> row,
  ) {
    return {
      ...row,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  static Future<void> ensureUpdatedAtColumn(
    Database db,
    String table,
  ) async {
    final cols = await db.rawQuery('PRAGMA table_info($table)');
    final names = cols.map((c) => c['name']?.toString() ?? '').toSet();
    if (!names.contains('updatedAt')) {
      await db.execute('ALTER TABLE $table ADD COLUMN updatedAt TEXT');
    }
  }
}

/// Stage 2: push outcome including the first per-row error so the
/// Sync button snackbar can show the real failure reason.
class _PushResult {
  final int pushed;
  final String? firstError;

  const _PushResult(this.pushed, this.firstError);
}
