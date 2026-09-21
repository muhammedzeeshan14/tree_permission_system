import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class ForwardedSourceRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<List<Map<String, dynamic>>> getSources() async {

    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "forwarded_source_master",
          equals: {"isActive": 1},
          orderBy: "displayOrder",
        );
        rows.sort((a, b) => ((a['displayOrder'] as num?)?.toInt() ?? 0)
            .compareTo((b['displayOrder'] as num?)?.toInt() ?? 0));
        return rows;
      } catch (e) {
        debugPrint('online getSources forwarded_source_master failed, falling back to local: $e');
      }
    }

    final db = await _db;

    return await db.query(

      "forwarded_source_master",

      where: "isActive=1",

      orderBy: "displayOrder",

    );

  }

}
