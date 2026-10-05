import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class BeatRepository {

  Future<List<Map<String, dynamic>>> getAll() async {

    if (OnlineMode.enabled) {
      try {
        final beats = await OnlineDatabase.select("beat_master");
        final sections =
            await OnlineDatabase.select("section_master");
        final names = <int, String>{
          for (final s in sections)
            (s["id"] as num).toInt():
                (s["sectionName"]?.toString() ?? ""),
        };
        final joined = beats.map((b) {
          final row = Map<String, dynamic>.from(b);
          final sectionId =
              (b["sectionId"] as num?)?.toInt();
          row["sectionName"] = sectionId == null
              ? ""
              : (names[sectionId] ?? "");
          return row;
        }).toList();
        joined.sort((a, b) {
          final sectionCompare =
              (a["sectionName"]?.toString() ?? "").compareTo(
                  b["sectionName"]?.toString() ?? "");
          if (sectionCompare != 0) return sectionCompare;
          return ((a["displayOrder"] as num?)?.toInt() ?? 0)
              .compareTo(
                  (b["displayOrder"] as num?)?.toInt() ?? 0);
        });
        return joined;
      } catch (_) {
        rethrow;
      }
    }

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
    beatName = beatName.trim();
    if (beatName.isEmpty) throw ArgumentError("Enter the beat name.");


    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.insert(
          "beat_master",
          {
            "sectionId": sectionId,
            "beatName": beatName,
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
    beatName = beatName.trim();
    if (beatName.isEmpty) throw ArgumentError("Enter the beat name.");


    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.update(
          "beat_master",
          id,
          {
            "sectionId": sectionId,
            "beatName": beatName,
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
    final usersLinks = OnlineMode.enabled
        ? await OnlineDatabase.select('users', equals: {'beatId': id}, limit: 1)
        : await (await DatabaseHelper.instance.database).query('users', where: 'beatId=?', whereArgs: [id], limit: 1);
    if (usersLinks.isNotEmpty) throw StateError('This beat is used by users. Deactivate it instead of deleting it.');
    final applicationsLinks = OnlineMode.enabled
        ? await OnlineDatabase.select('applications', equals: {'beatId': id}, limit: 1)
        : await (await DatabaseHelper.instance.database).query('applications', where: 'beatId=?', whereArgs: [id], limit: 1);
    if (applicationsLinks.isNotEmpty) throw StateError('This beat is used by applications. Deactivate it instead of deleting it.');


  if (OnlineMode.enabled) {
    try {
      await OnlineDatabase.delete(
        "beat_master",
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

    "beat_master",

    where: "id=?",

    whereArgs: [id],

  );

}

Future<List<Map<String, dynamic>>> getBySection(

  int sectionId,

) async {

  if (OnlineMode.enabled) {
    try {
      return await OnlineDatabase.select(
        "beat_master",
        equals: {"sectionId": sectionId, "isActive": 1},
        orderBy: "displayOrder",
      );
    } catch (_) {
      rethrow;
    }
  }

  final db = await DatabaseHelper.instance.database;

  return await db.query(

    "beat_master",

    where: "sectionId=? AND isActive=1",

    whereArgs: [sectionId],

    orderBy: "displayOrder",

  );

}

}