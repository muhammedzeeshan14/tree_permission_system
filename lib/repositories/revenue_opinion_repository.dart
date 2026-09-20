import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/revenue_opinion_model.dart';

class RevenueOpinionRepository {
  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<List<RevenueOpinionModel>> getAll() async {
    final db = await _db;

    final result = await db.query(
      "revenue_opinion_master",
      orderBy: "displayOrder",
    );

    return result
        .map(
          (e) => RevenueOpinionModel.fromMap(e),
        )
        .toList();
  }

  Future<List<RevenueOpinionModel>>
      getActive() async {
    final db = await _db;

    final result = await db.query(
      "revenue_opinion_master",
      where: "isActive=1",
      orderBy: "displayOrder",
    );

    return result
        .map(
          (e) => RevenueOpinionModel.fromMap(e),
        )
        .toList();
  }

  Future<void> insert(
      RevenueOpinionModel item) async {
    final db = await _db;

    await db.insert(
      "revenue_opinion_master",
      item.toMap(),
    );
  }

  Future<void> update(
      RevenueOpinionModel item) async {
    final db = await _db;

    await db.update(
      "revenue_opinion_master",
      item.toMap(),
      where: "id=?",
      whereArgs: [item.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db;

    await db.delete(
      "revenue_opinion_master",
      where: "id=?",
      whereArgs: [id],
    );
  }

Future<void> loadDefaultRevenueOpinions() async {

  final db = await _db;

  final count = Sqflite.firstIntValue(

    await db.rawQuery(

      "SELECT COUNT(*) FROM revenue_opinion_master",

    ),

  ) ?? 0;

  if (count > 0) {

    return;

  }

  await db.insert(

    "revenue_opinion_master",

    {

      "revenueOpinion":
          "Private Land",

      "code": "PL",

      "officeName":
          "Tahsildar, Mysuru Taluk",

      "officeAddress":
          "Mini Vidhana Soudha, Nazarbad, Mysuru - 570010",

      "remarks": "",

      "displayOrder": 1,

      "isActive": 1,

    },

  );

  await db.insert(

    "revenue_opinion_master",

    {

      "revenueOpinion":
          "Government Land",

      "code": "GL",

      "officeName":
          "Tahsildar, Mysuru Taluk",

      "officeAddress":
          "Mini Vidhana Soudha, Nazarbad, Mysuru - 570010",

      "remarks": "",

      "displayOrder": 2,

      "isActive": 1,

    },

  );

  await db.insert(

    "revenue_opinion_master",

    {

      "revenueOpinion":
          "Deemed Forest",

      "code": "DF",

      "officeName":
          "Deputy Commissioner, Mysuru",

      "officeAddress":
          "Deputy Commissioner's Office, Mysuru - 570001",

      "remarks": "",

      "displayOrder": 3,

      "isActive": 1,

    },

  );

  await db.insert(

    "revenue_opinion_master",

    {

      "revenueOpinion":
          "Not Required",

      "code": "NR",

      "officeName": "",

      "officeAddress": "",

      "remarks":
          "Revenue opinion not required.",

      "displayOrder": 4,

      "isActive": 1,

    },

  );

}

Future<RevenueOpinionModel?> getById(int id) async {

  final db = await _db;

  final result = await db.query(

    "revenue_opinion_master",

    where: "id=?",

    whereArgs: [id],

    limit: 1,

  );

  if (result.isEmpty) {

    return null;

  }

  return RevenueOpinionModel.fromMap(
    result.first,
  );

}

}