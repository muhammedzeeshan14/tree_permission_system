import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class ApplicationForwardReferenceRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<void> saveReference({

    required int applicationId,

    required int sourceId,

    String sourceKind = 'SOURCE',

    required String referenceNumber,

    required String referenceDate,

    required int displayOrder,

  }) async {

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.insert(

          "application_forward_references",

          {

            "applicationId": applicationId,

            "sourceId": sourceId,

            "sourceKind": sourceKind,

            "referenceNumber": referenceNumber,

            "referenceDate": referenceDate,

            "displayOrder": displayOrder,

          },

        );
        return;
      } catch (e) {
        debugPrint('online saveReference application_forward_references failed, falling back to local: $e');
      }
    }

    final db = await _db;

    await db.insert(

      "application_forward_references",

      {

        "applicationId": applicationId,

        "sourceId": sourceId,

        "sourceKind": sourceKind,

        "referenceNumber": referenceNumber,

        "referenceDate": referenceDate,

        "displayOrder": displayOrder,

      },

    );

  }

  Future<List<Map<String, dynamic>>> getReferences(

      int applicationId) async {

    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(

          "application_forward_references",

          equals: {"applicationId": applicationId},

          orderBy: "displayOrder",

        );
        rows.sort((a, b) =>
            (((a["displayOrder"] as num?)?.toInt() ?? 0)).compareTo(
                (b["displayOrder"] as num?)?.toInt() ?? 0));
        return rows;
      } catch (e) {
        debugPrint('online getReferences application_forward_references failed, falling back to local: $e');
      }
    }

    final db = await _db;

    return await db.query(

      "application_forward_references",

      where: "applicationId=?",

      whereArgs: [applicationId],

      orderBy: "displayOrder",

    );

  }

  Future<void> deleteReferences(
      int applicationId) async {

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(

          "application_forward_references",

          column: "applicationId",

          value: applicationId,

        );
        return;
      } catch (e) {
        debugPrint('online deleteReferences application_forward_references failed, falling back to local: $e');
      }
    }

    final db = await _db;

    await db.delete(

      "application_forward_references",

      where: "applicationId=?",

      whereArgs: [applicationId],

    );

  }

}