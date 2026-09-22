import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/tree_count_site_model.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class TreeCountSiteRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<int> insert(
      TreeCountSiteModel item) async {

    if (OnlineMode.enabled) {
      try {
        return await OnlineDatabase.insert(
          "application_tree_count_site",
          item.toMap(),
        );
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    return await db.insert(

      "application_tree_count_site",

      item.toMap(),

    );

  }

  Future<void> update(
      TreeCountSiteModel item) async {

    if (OnlineMode.enabled) {
      try {
        if (item.id != null) {
          await OnlineDatabase.update(
            "application_tree_count_site",
            item.id!,
            item.toMap(),
          );
        }
        return;
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    await db.update(

      "application_tree_count_site",

      item.toMap(),

      where: "id=?",

      whereArgs: [item.id],

    );

  }

  Future<List<TreeCountSiteModel>>
      getSites(int applicationId) async {

    if (OnlineMode.enabled) {
      try {
        final result = await OnlineDatabase.select(
          "application_tree_count_site",
          equals: {"applicationId": applicationId},
          orderBy: "displayOrder",
        );
        return result
            .map((e) =>
                TreeCountSiteModel.fromMap(e))
            .toList();
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    final result = await db.query(

      "application_tree_count_site",

      where: "applicationId=?",

      whereArgs: [applicationId],

      orderBy: "displayOrder",

    );

    return result
        .map((e) =>
            TreeCountSiteModel.fromMap(e))
        .toList();

  }

  Future<void> delete(int id) async {

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(
          "application_tree_count_site",
          column: "id",
          value: id,
        );
        return;
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    await db.delete(

      "application_tree_count_site",

      where: "id=?",

      whereArgs: [id],

    );

  }

  Future<void> deleteSite(int siteId) async {

  if (OnlineMode.enabled) {
    try {
      await OnlineDatabase.delete(
        "application_tree_count",
        column: "siteId",
        value: siteId,
      );
      await OnlineDatabase.delete(
        "application_tree_count_site",
        column: "id",
        value: siteId,
      );
      return;
    } catch (_) {
      /* fall through to local */
    }
  }

  final db = await _db;

  await db.transaction((txn) async {

    await txn.delete(

      "application_tree_count",

      where: "siteId=?",

      whereArgs: [siteId],

    );

    await txn.delete(

      "application_tree_count_site",

      where: "id=?",

      whereArgs: [siteId],

    );

  });

}

}