import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/application_revenue_opinion_model.dart';

class ApplicationRevenueOpinionRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<ApplicationRevenueOpinionModel?>
      getByApplication(
      int applicationId) async {

    final db = await _db;

    final result = await db.query(

      "application_revenue_opinion",

      where: "applicationId=?",

      whereArgs: [applicationId],

      limit: 1,

    );

    if(result.isEmpty){

      return null;

    }

    return ApplicationRevenueOpinionModel
        .fromMap(result.first);

  }

  Future<void> save(
      ApplicationRevenueOpinionModel item) async{

    final db=await _db;

    final existing=await getByApplication(
      item.applicationId,
    );

    if(existing==null){

      await db.insert(

        "application_revenue_opinion",

        item.toMap(),

      );

    }else{

      await db.update(

  "application_revenue_opinion",

  {

    "applicationId": item.applicationId,

    "revenueOpinionId": item.revenueOpinionId,

  },

  where: "applicationId=?",

  whereArgs: [

    item.applicationId,

  ],

);

    }

  }

}