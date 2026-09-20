import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class ApplicationDocumentRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      dbHelper.database;

  Future<List<Map<String, dynamic>>> getDocuments(
      int applicationId) async {

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

    final db = await _db;

    return await db.insert(

      "application_documents",

      data,

    );

  }

  Future<void> deleteDocument(
      int id) async {

    final db = await _db;

    await db.delete(

      "application_documents",

      where: "id=?",

      whereArgs: [id],

    );

  }

}