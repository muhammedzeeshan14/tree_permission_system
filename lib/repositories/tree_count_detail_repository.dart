import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/tree_count_detail_model.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class TreeCountDetailRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<void> insert(
      TreeCountDetailModel item) async {

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.insert(
          "application_tree_count",
          item.toMap(),
        );
        return;
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    await db.insert(

      "application_tree_count",

      item.toMap(),

    );

  }

  Future<List<TreeCountDetailModel>>
      getBySite(int siteId) async {

    if (OnlineMode.enabled) {
      try {
        final result = await OnlineDatabase.select(
          "application_tree_count",
          equals: {"siteId": siteId},
          orderBy: "displayOrder",
        );
        return result
            .map((e) =>
                TreeCountDetailModel.fromMap(e))
            .toList();
      } catch (_) {
        /* fall through to local */
      }
    }

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

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(
          "application_tree_count",
          column: "siteId",
          value: siteId,
        );
        return;
      } catch (_) {
        /* fall through to local */
      }
    }

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