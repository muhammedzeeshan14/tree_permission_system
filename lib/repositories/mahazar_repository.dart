import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/mahazar_model.dart';

class MahazarRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<void> save(
      MahazarModel item) async {

    final db = await _db;

    await db.delete(

      "application_mahazar",

      where: "applicationId=?",

      whereArgs: [item.applicationId],

    );

    await db.insert(

      "application_mahazar",

      item.toMap(),

    );

  }

  Future<MahazarModel?> getByApplication(
      int applicationId) async {

    final db = await _db;

    final result = await db.query(

      "application_mahazar",

      where: "applicationId=?",

      whereArgs: [applicationId],

      limit: 1,

    );

    if (result.isEmpty) {

      return null;

    }

    return MahazarModel.fromMap(
      result.first,
    );

  }

}