import '../database/database_helper.dart';

class BeatRepository {

  Future<List<Map<String, dynamic>>> getAll() async {

    final db = await DatabaseHelper.instance.database;

    return await db.rawQuery("""

SELECT

beat_master.*,

section_master.sectionName

FROM beat_master

LEFT JOIN section_master

ON beat_master.sectionId = section_master.id

ORDER BY

section_master.sectionName,

beat_master.displayOrder

""");

  }

  Future<void> insert({

    required int sectionId,

    required String beatName,

required int displayOrder,

    required bool isActive,

    String kannadaName = "",

  }) async {

    final db = await DatabaseHelper.instance.database;

    await db.insert(

      "beat_master",

      {

        "sectionId": sectionId,

        "beatName": beatName,

        "kannadaName": kannadaName,

"displayOrder": displayOrder,

        "isActive": isActive ? 1 : 0,

      },

    );

  }

  Future<void> update({

  required int id,

  required int sectionId,

  required String beatName,

  required int displayOrder,

  required bool isActive,

  String kannadaName = "",

}) async {

    final db = await DatabaseHelper.instance.database;

    await db.update(

      "beat_master",

      {

  "sectionId": sectionId,

  "beatName": beatName,

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

    "beat_master",

    where: "id=?",

    whereArgs: [id],

  );

}

Future<List<Map<String, dynamic>>> getBySection(

  int sectionId,

) async {

  final db = await DatabaseHelper.instance.database;

  return await db.query(

    "beat_master",

    where: "sectionId=? AND isActive=1",

    whereArgs: [sectionId],

    orderBy: "displayOrder",

  );

}

}