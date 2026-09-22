import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class PoleRateRepository {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => await dbHelper.database;

  // ============================================================
  // GET ALL POLE RATES
  // ============================================================

  Future<List<Map<String, dynamic>>> getAllRates() async {
    if (OnlineMode.enabled) {
      try {
        final rates = await OnlineDatabase.select('pole_rate_master');
        final species = await OnlineDatabase.select(
          'master_data',
          equals: {'masterType': 'Species'},
        );
        final names = <int, String>{
          for (final m in species)
            (m['id'] as num).toInt(): (m['value']?.toString() ?? ''),
        };
        final rows = [
          for (final p in rates)
            {
              ...Map<String, dynamic>.from(p),
              'speciesName':
                  names[(p['speciesId'] as num?)?.toInt()],
            },
        ];
        rows.sort((a, b) {
          final speciesName = ((a['speciesName'] as String?) ?? '')
              .compareTo((b['speciesName'] as String?) ?? '');
          if (speciesName != 0) return speciesName;
          final order =
              (((a['displayOrder'] as num?)?.toInt() ?? 0)).compareTo(
            ((b['displayOrder'] as num?)?.toInt() ?? 0),
          );
          if (order != 0) return order;
          return (((a['id'] as num?)?.toInt() ?? 0))
              .compareTo((b['id'] as num?)?.toInt() ?? 0);
        });
        return rows;
      } catch (e) {
        debugPrint('online getAllRates pole_rate_master failed, falling back to local: $e');
      }
    }
    final db = await _db;

    return await db.rawQuery('''
      SELECT
        p.id,
        p.speciesId,
        p.lengthFrom,
        p.lengthUpto,
        p.girthFrom,
        p.girthUpto,
        p.rate,
        p.category,
        p.displayOrder,
        p.isActive,
        m.value AS speciesName
      FROM pole_rate_master p
      LEFT JOIN master_data m
        ON p.speciesId = m.id
        AND m.masterType = 'Species'
      ORDER BY
        m.value ASC,
        p.displayOrder ASC,
        p.id ASC
    ''');
  }

  // ============================================================
  // GET ACTIVE RATES FOR A SPECIES
  // ============================================================

  Future<List<Map<String, dynamic>>> getRatesBySpecies(
    int speciesId,
  ) async {
    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          'pole_rate_master',
          equals: {'speciesId': speciesId, 'isActive': 1},
        );
        rows.sort((a, b) {
          final order =
              (((a['displayOrder'] as num?)?.toInt() ?? 0)).compareTo(
            ((b['displayOrder'] as num?)?.toInt() ?? 0),
          );
          if (order != 0) return order;
          return (((a['id'] as num?)?.toInt() ?? 0))
              .compareTo((b['id'] as num?)?.toInt() ?? 0);
        });
        return rows;
      } catch (e) {
        debugPrint('online getRatesBySpecies pole_rate_master failed, falling back to local: $e');
      }
    }
    final db = await _db;

    return await db.query(
      'pole_rate_master',
      where: 'speciesId = ? AND isActive = 1',
      whereArgs: [speciesId],
      orderBy: 'displayOrder ASC, id ASC',
    );
  }

  // ============================================================
  // INSERT
  // ============================================================

  Future<int> insertRate({
    required int speciesId,
    double? lengthFrom,
    double? lengthUpto,
    double? girthFrom,
    double? girthUpto,
    required double rate,
    required String category,
    required int displayOrder,
    bool isActive = true,
  }) async {
    if (OnlineMode.enabled) {
      try {
        return await OnlineDatabase.insert(
          'pole_rate_master',
          {
            'speciesId': speciesId,
            'lengthFrom': lengthFrom,
            'lengthUpto': lengthUpto,
            'girthFrom': girthFrom,
            'girthUpto': girthUpto,
            'rate': rate,
            'category': category,
            'displayOrder': displayOrder,
            'isActive': isActive ? 1 : 0,
          },
        );
      } catch (e) {
        debugPrint('online insertRate pole_rate_master failed, falling back to local: $e');
      }
    }
    final db = await _db;

    return await db.insert(
      'pole_rate_master',
      {
        'speciesId': speciesId,
        'lengthFrom': lengthFrom,
        'lengthUpto': lengthUpto,
        'girthFrom': girthFrom,
        'girthUpto': girthUpto,
        'rate': rate,
        'category': category,
        'displayOrder': displayOrder,
        'isActive': isActive ? 1 : 0,
      },
    );
  }

  // ============================================================
  // UPDATE
  // ============================================================

  Future<int> updateRate({
    required int id,
    required int speciesId,
    double? lengthFrom,
    double? lengthUpto,
    double? girthFrom,
    double? girthUpto,
    required double rate,
    required String category,
    required int displayOrder,
    required bool isActive,
  }) async {
    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.update(
          'pole_rate_master',
          id,
          {
            'speciesId': speciesId,
            'lengthFrom': lengthFrom,
            'lengthUpto': lengthUpto,
            'girthFrom': girthFrom,
            'girthUpto': girthUpto,
            'rate': rate,
            'category': category,
            'displayOrder': displayOrder,
            'isActive': isActive ? 1 : 0,
          },
        );
        return 1;
      } catch (e) {
        debugPrint('online updateRate pole_rate_master failed, falling back to local: $e');
      }
    }
    final db = await _db;

    return await db.update(
      'pole_rate_master',
      {
        'speciesId': speciesId,
        'lengthFrom': lengthFrom,
        'lengthUpto': lengthUpto,
        'girthFrom': girthFrom,
        'girthUpto': girthUpto,
        'rate': rate,
        'category': category,
        'displayOrder': displayOrder,
        'isActive': isActive ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<int> deleteRate(int id) async {
    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(
          'pole_rate_master',
          column: 'id',
          value: id,
        );
        return 1;
      } catch (e) {
        debugPrint('online deleteRate pole_rate_master failed, falling back to local: $e');
      }
    }
    final db = await _db;

    return await db.delete(
      'pole_rate_master',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // ACTIVATE / DEACTIVATE
  // ============================================================

  Future<int> setActive(
    int id,
    bool isActive,
  ) async {
    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.update(
          'pole_rate_master',
          id,
          {
            'isActive': isActive ? 1 : 0,
          },
        );
        return 1;
      } catch (e) {
        debugPrint('online setActive pole_rate_master failed, falling back to local: $e');
      }
    }
    final db = await _db;

    return await db.update(
      'pole_rate_master',
      {
        'isActive': isActive ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}