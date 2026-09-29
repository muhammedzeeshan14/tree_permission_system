import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../repositories/officer_repository.dart';
import 'online_database.dart';
import 'online_mode.dart';

/// Resolves letter To / Copy-To addresses for unified forward
/// references (item 2-4):
/// - SOURCE  -> forwarded source; ACF/DCF use officer master
/// - AGENCY  -> government agency master Kannada address
/// - OFFICER -> officer directory master address
/// To-address uses 2 lines; copy-to uses a single comma line.
class ForwardedAddressService {
  ForwardedAddressService._();

  static Future<Map<String, dynamic>?> _row(
    String table,
    int id,
  ) async {
    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          table,
          equals: {'id': id},
          limit: 1,
        );
        if (rows.isNotEmpty) return rows.first;
      } catch (e) {
        debugPrint('forwarded address online $table#$id: $e');
      }
    }
    try {
      final Database db =
          await DatabaseHelper.instance.database;
      final rows = await db.query(
        table,
        where: 'id=?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isNotEmpty) return rows.first;
    } catch (e) {
      debugPrint('forwarded address local $table#$id: $e');
    }
    return null;
  }

  static String _twoLines(String first, String second) => [first, second]
      .expand((part) => part.split(RegExp(r'[\r\n]+')))
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.isNotEmpty).join('\n');

  /// 2-line To address. Falls back to [fallback] text.
  static Future<String> toAddress({
    required String kind,
    required int? sourceId,
    required String fallback,
  }) async {
    final normalizedKind = kind.trim().toUpperCase();
    if (sourceId == null || normalizedKind == 'OTHER') return _twoLines(fallback, '');
    if (normalizedKind == 'AGENCY') {
      final row = await _row('revenue_opinion_master', sourceId);
      if (row == null) return fallback;
      final designation = row['kannadaDesignation']?.toString().trim() ?? '';
      final address = row['kannadaOfficeAddress']?.toString().trim() ?? '';
      if (designation.isEmpty || address.isEmpty) {
        throw StateError('Complete Kannada designation and office address in the Revenue Opinion master.');
      }
      return _twoLines(designation, address);
    }
    if (normalizedKind == 'OFFICER') {
      final row = await _row('officer_directory', sourceId);
      if (row == null) return fallback;
      try {
        return OfficerRepository.formatAddress(row);
      } catch (_) {
        return fallback;
      }
    }
    return OfficerRepository().sourceAddress(sourceId, fallback);
  }

  /// Copy-To lines must each print as ONE line:
  /// applicant/officer designation/reference name + address/office
  /// postal address, all comma-separated. Any multi-line fallback
  /// text is collapsed so a copy entry never splits into 2 lines.
  static String _oneLine(String value) {
    return value
        .split(RegExp(r'[\r\n]+'))
        .map((s) => s.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((s) => s.isNotEmpty)
        .join(', ');
  }

  /// Single-line comma Copy-To address.
  static Future<String> copyToAddress({
    required String kind,
    required int? sourceId,
    required String fallback,
  }) async {
    final normalizedKind = kind.trim().toUpperCase();
    if (sourceId == null) return _oneLine(fallback);
    if (normalizedKind == 'OTHER') return _oneLine(fallback);
    if (normalizedKind == 'AGENCY') {
      return _oneLine(await toAddress(kind: kind, sourceId: sourceId, fallback: fallback));
    }
    if (normalizedKind == 'OFFICER') {
      final row = await _row('officer_directory', sourceId);
      if (row == null) return _oneLine(fallback);
      try {
        return OfficerRepository.formatAddress(
          row,
          copyTo: true,
        );
      } catch (_) {
        return _oneLine(fallback);
      }
    }
    return _oneLine(await OfficerRepository()
        .sourceAddress(sourceId, fallback, copyTo: true));
  }
}
