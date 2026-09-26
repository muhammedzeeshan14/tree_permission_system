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

  static String _twoLines(String first, String second) {
    final a = first.replaceAll(RegExp(r'\s+'), ' ').trim();
    final b = second.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    return '$a\n$b';
  }

  /// 2-line To address. Falls back to [fallback] text.
  static Future<String> toAddress({
    required String kind,
    required int? sourceId,
    required String fallback,
  }) async {
    final normalizedKind = kind.trim().toUpperCase();
    if (sourceId == null) return fallback;
    if (normalizedKind == 'AGENCY') {
      final row = await _row('revenue_opinion_master', sourceId);
      if (row == null) return fallback;
      final name =
          row['kannadaName']?.toString().trim() ?? '';
      final designation =
          row['kannadaDesignation']?.toString().trim() ?? '';
      final address =
          row['kannadaOfficeAddress']?.toString().trim() ?? '';
      final first = [name, designation]
          .where((s) => s.isNotEmpty)
          .join(', ');
      final resolved = _twoLines(first, address);
      if (resolved.isNotEmpty) return resolved;
      return _twoLines(
        (row['officeName']?.toString() ?? ''),
        (row['officeAddress']?.toString() ?? ''),
      ).isNotEmpty
          ? _twoLines(
              (row['officeName']?.toString() ?? ''),
              (row['officeAddress']?.toString() ?? ''),
            )
          : fallback;
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
    if (normalizedKind == 'AGENCY') {
      final row = await _row('revenue_opinion_master', sourceId);
      if (row == null) return _oneLine(fallback);
      final name =
          row['kannadaName']?.toString().trim() ?? '';
      final designation =
          row['kannadaDesignation']?.toString().trim() ?? '';
      final address =
          row['kannadaOfficeAddress']?.toString().trim() ?? '';
      final parts = [name, designation, address]
          .where((s) => s.isNotEmpty)
          .join(', ');
      if (parts.isNotEmpty) return parts;
      return _oneLine(await OfficerRepository()
          .sourceAddress(sourceId, fallback, copyTo: true));
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
