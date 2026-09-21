import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class SectionRepository {

  Future<List<Map<String, dynamic>>> getAll() async {

    if (OnlineMode.enabled) {
      try {
        return await OnlineDatabase.select(
          "section_master",
          orderBy: "displayOrder",
        );
      } catch (_) {
        // Fall through to local.
      }
    }

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

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.insert(
          "section_master",
          {
            "sectionName": sectionName,
            "kannadaName": kannadaName,
            "displayOrder": displayOrder,
            "isActive": isActive ? 1 : 0,
          },
        );
        return;
      } catch (_) {
        // Fall through to local.
      }
    }

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

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.update(
          "section_master",
          id,
          {
            "sectionName": sectionName,
            "kannadaName": kannadaName,
            "displayOrder": displayOrder,
            "isActive": isActive ? 1 : 0,
          },
        );
        return;
      } catch (_) {
        // Fall through to local.
      }
    }

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

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(
          "section_master",
          column: "id",
          value: id,
        );
        return;
      } catch (_) {
        // Fall through to local.
      }
    }

    final db = await DatabaseHelper.instance.database;

    await db.delete(

      "section_master",

      where: "id=?",

      whereArgs: [id],

    );

  }
    Future<List<Map<String, dynamic>>> getActive() async {

    if (OnlineMode.enabled) {
      try {
        return await OnlineDatabase.select(
          "section_master",
          equals: {"isActive": 1},
          orderBy: "displayOrder",
        );
      } catch (_) {
        // Fall through to local.
      }
    }

    final db = await DatabaseHelper.instance.database;

    return await db.query(

      "section_master",

      where: "isActive=?",

      whereArgs: [1],

      orderBy: "displayOrder",

    );

  }

}