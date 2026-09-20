import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class ForwardedSourceRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<List<Map<String, dynamic>>> getSources() async {

    final db = await _db;

    return await db.query(

      "forwarded_source_master",

      where: "isActive=1",

      orderBy: "displayOrder",

    );

  }

}