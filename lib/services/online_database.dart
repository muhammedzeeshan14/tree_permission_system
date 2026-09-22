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

  static Future<int> insert(
    String table,
    Map<String, Object?> row,
  ) async {
    try {
      final payload = Map<String, dynamic>.from(row);
      if (payload['id'] == null) payload.remove('id');
      payload['updatedAt'] ??= DateTime.now().toIso8601String();
      try {
        final inserted = await _client
            .from(table)
            .insert(payload)
            .select('id')
            .single();
        return (inserted['id'] as num).toInt();
      } catch (_) {
        // Tables without an `id` column (e.g. government_approvals
        // keyed by applicationId): plain insert, caller re-reads.
        await _client.from(table).insert(payload);
        return 0;
      }
    } catch (e) {
      debugPrint('online insert $table failed: $e');
      rethrow;
    }
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
