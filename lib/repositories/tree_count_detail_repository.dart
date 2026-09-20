import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/tree_count_detail_model.dart';

class TreeCountDetailRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<void> insert(
      TreeCountDetailModel item) async {

    final db = await _db;

    await db.insert(

      "application_tree_count",

      item.toMap(),

    );

  }

  Future<List<TreeCountDetailModel>>
      getBySite(int siteId) async {

    final db = await _db;

    final result = await db.query(

      "application_tree_count",

      where: "siteId=?",

      whereArgs: [siteId],

      orderBy: "displayOrder",

    );

    return result
        .map((e) =>
            TreeCountDetailModel.fromMap(e))
        .toList();

  }

  Future<void> deleteBySite(
      int siteId) async {

    final db = await _db;

    await db.delete(

      "application_tree_count",

      where: "siteId=?",

      whereArgs: [siteId],

    );

  }

  Future<void> saveAll({

    required int siteId,

    required List<TreeCountDetailModel> items,

  }) async {

    await deleteBySite(siteId);

    for (final item in items) {

      item.siteId = siteId;

      await insert(item);

    }

  }

}