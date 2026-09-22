import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import 'online_database.dart';
import 'online_mode.dart';
import 'supabase_service.dart';

/// Item 9: continuous unique office numbers across all application
/// types: MYS/RFO/<year>/1, /2, /3 ...
///
/// Online: a shared `office_number_counter` row is incremented with an
/// optimistic lock (retried), so two devices never get the same number.
/// Offline/unconfigured: max trailing number in the local database + 1.
class OfficeNumberService {
  OfficeNumberService._();

  static int _localLast = 0;

  static Future<String> nextOfficeNumber() async {
    final year = DateTime.now().year.toString();
    final number = OnlineMode.enabled
        ? await _nextOnline()
        : await _nextLocal();
    return 'MYS/RFO/$year/$number';
  }

  static Future<int> _nextOnline() async {
    try {
      final client = SupabaseService.client;
      if (client == null) return _nextLocal();
      for (var attempt = 0; attempt < 5; attempt++) {
        final rows = await client
            .from('office_number_counter')
            .select()
            .eq('id', 1)
            .limit(1) as List;
        if (rows.isEmpty) {
          try {
            await client.from('office_number_counter').insert(
              {'id': 1, 'last_number': 1},
            );
            return 1;
          } catch (_) {
            continue;
          }
        }
        final current =
            (rows.first['last_number'] as num?)?.toInt() ?? 0;
        final updated = await client
            .from('office_number_counter')
            .update({'last_number': current + 1})
            .eq('id', 1)
            .eq('last_number', current)
            .select('id') as List;
        if (updated.isNotEmpty) return current + 1;
      }
    } catch (e) {
      debugPrint('office counter online failed: $e');
    }
    return _nextLocal();
  }

  static Future<int> _nextLocal() async {
    try {
      final Database db =
          await DatabaseHelper.instance.database;
      final rows = await db.query(
        'applications',
        columns: ['officeNumber'],
      );
      var max = _localLast;
      for (final row in rows) {
        final text = row['officeNumber']?.toString() ?? '';
        final tail = text.split('/').last.trim();
        final number = int.tryParse(tail) ?? 0;
        if (number > max) max = number;
      }
      _localLast = max + 1;
      return _localLast;
    } catch (_) {
      _localLast += 1;
      return _localLast;
    }
  }
}
