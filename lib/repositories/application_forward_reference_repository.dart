import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class ApplicationForwardReferenceRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<void> saveReference({

    required int applicationId,

    required int sourceId,

    required String referenceNumber,

    required String referenceDate,

    required int displayOrder,

  }) async {

    final db = await _db;

    await db.insert(

      "application_forward_references",

      {

        "applicationId": applicationId,

        "sourceId": sourceId,

        "referenceNumber": referenceNumber,

        "referenceDate": referenceDate,

        "displayOrder": displayOrder,

      },

    );

  }

  Future<List<Map<String, dynamic>>> getReferences(

      int applicationId) async {

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

    final db = await _db;

    await db.delete(

      "application_forward_references",

      where: "applicationId=?",

      whereArgs: [applicationId],

    );

  }

}