import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class PermissionTypeRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<List<Map<String, dynamic>>> getAll() async {

    final db = await _db;

    return await db.query(

      "permission_type_master",

      orderBy: "displayOrder",

    );

  }

  Future<List<Map<String, dynamic>>> getActive() async {

    final db = await _db;

    return await db.query(

      "permission_type_master",

      where: "isActive=1",

      orderBy: "displayOrder",

    );

  }

  Future<void> insert({

    required String permissionType,

    required int displayOrder,

    required bool isActive,

  }) async {

    final db = await _db;

    await db.insert(

      "permission_type_master",

      {

        "permissionType": permissionType,

        "displayOrder": displayOrder,

        "isActive": isActive ? 1 : 0,

      },

    );

  }

  Future<void> update({

    required int id,

    required String permissionType,

    required int displayOrder,

    required bool isActive,

  }) async {

    final db = await _db;

    await db.update(

      "permission_type_master",

      {

        "permissionType": permissionType,

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

      "permission_type_master",

      where: "id=?",

      whereArgs: [id],

    );

  }

}