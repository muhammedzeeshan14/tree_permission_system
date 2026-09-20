import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class ApplicationTypeRepository {

  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async => await dbHelper.database;

  Future<List<Map<String, dynamic>>> getAll() async {

    final db = await _db;

    return await db.query(
      "application_type_master",
      orderBy: "displayOrder ASC",
    );

  }

  Future<List<Map<String, dynamic>>> getActive() async {

    final db = await _db;

    return await db.query(
      "application_type_master",
      where: "isActive=?",
      whereArgs: [1],
      orderBy: "displayOrder ASC",
    );

  }

  Future<void> insert({

  required String applicationType,

  required String kannadaName,

  required String shortCode,

  required int displayOrder,

  required bool isActive,

}) async {

    final db = await _db;

    await db.insert(
      "application_type_master",
      {

        "applicationType": applicationType,

        "kannadaName": kannadaName,

        "shortCode": shortCode,

        "displayOrder": displayOrder,

        "isActive": isActive ? 1 : 0,

      },

    );

  }

  Future<void> update({

  required int id,

  required String applicationType,

  required String kannadaName,

  required String shortCode,

  required int displayOrder,

  required bool isActive,

}) async {

    final db = await _db;

    await db.update(

      "application_type_master",

      {

        "applicationType": applicationType,

        "kannadaName": kannadaName,

        "shortCode": shortCode,

        "displayOrder": displayOrder,

        "isActive": isActive ? 1 : 0,

      },

      where: "id=?",

      whereArgs: [id],

    );

  }

  Future<void> delete(int id) async {

    final db = await _db;

    await db.delete(

      "application_type_master",

      where: "id=?",

      whereArgs: [id],

    );

  }

}