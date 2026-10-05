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
        rethrow;
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
    sectionName = sectionName.trim();
    if (sectionName.isEmpty) throw ArgumentError("Enter the section name.");


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
        rethrow;
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
    sectionName = sectionName.trim();
    if (sectionName.isEmpty) throw ArgumentError("Enter the section name.");


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
        rethrow;
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
    final beatLinks = OnlineMode.enabled
        ? await OnlineDatabase.select('beat_master', equals: {'sectionId': id}, limit: 1)
        : await (await DatabaseHelper.instance.database).query('beat_master', where: 'sectionId=?', whereArgs: [id], limit: 1);
    if (beatLinks.isNotEmpty) throw StateError('This section is used by beat. Deactivate it instead of deleting it.');
    final usersLinks = OnlineMode.enabled
        ? await OnlineDatabase.select('users', equals: {'sectionId': id}, limit: 1)
        : await (await DatabaseHelper.instance.database).query('users', where: 'sectionId=?', whereArgs: [id], limit: 1);
    if (usersLinks.isNotEmpty) throw StateError('This section is used by users. Deactivate it instead of deleting it.');
    final applicationsLinks = OnlineMode.enabled
        ? await OnlineDatabase.select('applications', equals: {'sectionId': id}, limit: 1)
        : await (await DatabaseHelper.instance.database).query('applications', where: 'sectionId=?', whereArgs: [id], limit: 1);
    if (applicationsLinks.isNotEmpty) throw StateError('This section is used by applications. Deactivate it instead of deleting it.');


    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(
          "section_master",
          column: "id",
          value: id,
        );
        return;
      } catch (_) {
        rethrow;
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
        rethrow;
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