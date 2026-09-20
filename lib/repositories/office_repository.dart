import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class OfficeRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<Map<String, dynamic>?> getOffice() async {

    final db = await _db;

    final result = await db.query(

      "office_configuration",

      limit: 1,

    );

    if (result.isEmpty) {

      return null;

    }

    return result.first;

  }

}