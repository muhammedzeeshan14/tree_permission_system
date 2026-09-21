import '../database/database_helper.dart';

class SectionRepository {

  Future<List<Map<String, dynamic>>> getAll() async {

    final db = await DatabaseHelper.instance.database;

    return await db.query(

      "section_master",

      orderBy: "displayOrder",

    );

  }

  Future<void> insert({

    required String sectionName,

    required int displayOrder,

    required bool isActive,

    String kannadaName = "",

  }) async {

    final db = await DatabaseHelper.instance.database;

    await db.insert(

      "section_master",

      {

        "sectionName": sectionName,

        "kannadaName": kannadaName,

        "displayOrder": displayOrder,

        "isActive": isActive ? 1 : 0,

      },

    );

  }

  Future<void> update({

    required int id,

    required String sectionName,

    required int displayOrder,

    required bool isActive,

    String kannadaName = "",

  }) async {

    final db = await DatabaseHelper.instance.database;

    await db.update(

      "section_master",

      {

        "sectionName": sectionName,

        "kannadaName": kannadaName,

        "displayOrder": displayOrder,

        "isActive": isActive ? 1 : 0,

      },

      where: "id=?",

      whereArgs: [id],

    );

  }

  Future<void> delete(int id) async {

    final db = await DatabaseHelper.instance.database;

    await db.delete(

      "section_master",

      where: "id=?",

      whereArgs: [id],

    );

  }
    Future<List<Map<String, dynamic>>> getActive() async {

    final db = await DatabaseHelper.instance.database;

    return await db.query(

      "section_master",

      where: "isActive=?",

      whereArgs: [1],

      orderBy: "displayOrder",

    );

  }

}