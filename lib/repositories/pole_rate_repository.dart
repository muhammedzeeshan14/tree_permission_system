import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class PoleRateRepository {
  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => await dbHelper.database;

  // ============================================================
  // GET ALL POLE RATES
  // ============================================================

  Future<List<Map<String, dynamic>>> getAllRates() async {
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