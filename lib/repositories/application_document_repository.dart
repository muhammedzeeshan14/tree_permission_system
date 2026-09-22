import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class ApplicationDocumentRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      dbHelper.database;

  Future<List<Map<String, dynamic>>> getDocuments(
      int applicationId) async {

    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(

          "application_documents",

          equals: {"applicationId": applicationId},

          orderBy: "id",

          descending: true,

        );
        rows.sort((a, b) => (((b["id"] as num?)?.toInt() ?? 0))
            .compareTo((a["id"] as num?)?.toInt() ?? 0));
        return rows;
      } catch (e) {
        debugPrint('online getDocuments application_documents failed, falling back to local: $e');
      }
    }

    final db = await _db;

    return await db.query(

      "application_documents",

      where: "applicationId=?",

      whereArgs: [applicationId],

      orderBy: "id DESC",

    );

  }

  Future<int> insertDocument(
      Map<String, dynamic> data) async {

    if (OnlineMode.enabled) {
      try {
        return await OnlineDatabase.insert(

          "application_documents",

          data,

        );
      } catch (e) {
        debugPrint('online insertDocument application_documents failed, falling back to local: $e');
      }
    }

    final db = await _db;

    return await db.insert(

      "application_documents",

      data,

    );

  }

  Future<void> deleteDocument(
      int id) async {

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(

          "application_documents",

          column: "id",

          value: id,

        );
        return;
      } catch (e) {
        debugPrint('online deleteDocument application_documents failed, falling back to local: $e');
      }
    }

    final db = await _db;

    await db.delete(

      "application_documents",

      where: "id=?",

      whereArgs: [id],

    );

  }

}