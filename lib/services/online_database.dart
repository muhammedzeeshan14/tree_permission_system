import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Stage 3: thin direct-access layer over Supabase Postgres.
///
/// Column names match the local sqflite schema exactly (camelCase), so
/// repository maps can be sent as-is. Throws on failure so callers can
/// fall back to local storage when offline.
class OnlineDatabase {
  OnlineDatabase._();

  static SupabaseClient get _client => SupabaseService.client!;

  static Future<void> upsert(String table, Map<String, dynamic> row, {required String onConflict}) async {
    await _client.from(table).upsert(row, onConflict: onConflict);
  }

  static Future<List<Map<String, dynamic>>> select(
    String table, {
    Map<String, Object?>? equals,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      dynamic query = _client.from(table).select();
      equals?.forEach((key, value) {
        query = query.eq(key, value);
      });
      if (orderBy != null) {
        query = query.order(orderBy, ascending: !descending);
      }
      if (limit != null) {
        query = query.limit(limit);
      }
      final rows = await query as List;
      return rows
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      debugPrint('online select $table failed: $e');
      rethrow;
    }
  }

  /// Paged reads avoid silently stopping at the server's default row limit.
  static Future<List<Map<String, dynamic>>> selectAll(
    String table, {Map<String, Object?>? equals, String? orderBy,
    bool descending = false, String columns = '*',
    String? inColumn, List<Object>? inValues,
  }) async {
    if (inValues != null && inValues.isEmpty) return [];
    final result = <Map<String, dynamic>>[];
    const pageSize = 500;
    for (var offset = 0; ; offset += pageSize) {
      dynamic query = _client.from(table).select(columns);
      equals?.forEach((key, value) { query = query.eq(key, value); });
      if (inColumn != null && inValues != null) query = query.inFilter(inColumn, inValues);
      query = query.order(orderBy ?? 'id', ascending: !descending);
      if (orderBy != null && orderBy != 'id') query = query.order('id');
      final page = await query.range(offset, offset + pageSize - 1) as List;
      result.addAll(page.map((row) => Map<String, dynamic>.from(row as Map)));
      if (page.length < pageSize) return result;
    }
  }

  static Future<int> insert(
    String table,
    Map<String, Object?> row,
  ) async {
    try {
      final payload = Map<String, dynamic>.from(row);
      if (payload['id'] == null) payload.remove('id');
      payload['updatedAt'] ??= DateTime.now().toIso8601String();
      // These tables use applicationId (or composite keys), not id.
      // Never retry an ambiguous failed insert: it may already have committed.
      const withoutId = {'application_verifications', 'tree_verifications',
        'application_tree_officer', 'government_approvals'};
      if (withoutId.contains(table)) {
        await _client.from(table).insert(payload);
        return 0;
      }
      final inserted = await _client.from(table).insert(payload).select('id').single();
      return (inserted['id'] as num).toInt();
    } catch (e) {
      debugPrint('online insert $table failed: $e');
      rethrow;
    }
  }

  static Future<void> insertMany(String table, List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return;
    final now = DateTime.now().toIso8601String();
    await _client.from(table).insert(rows.map((row) => {
      ...row, 'updatedAt': row['updatedAt'] ?? now,
    }).toList());
  }

  static Future<void> update(
    String table,
    int id,
    Map<String, Object?> row,
  ) async {
    try {
      final payload = Map<String, dynamic>.from(row);
      payload.remove('id');
      payload['updatedAt'] = DateTime.now().toIso8601String();
      await _client.from(table).update(payload).eq('id', id);
    } catch (e) {
      debugPrint('online update $table#$id failed: $e');
      rethrow;
    }
  }

  static Future<void> delete(
    String table, {
    required String column,
    required Object value,
  }) async {
    try {
      await _client.from(table).delete().eq(column, value);
    } catch (e) {
      debugPrint('online delete $table failed: $e');
      rethrow;
    }
  }
}
