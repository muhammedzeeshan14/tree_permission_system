import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/application_revenue_opinion_model.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class ApplicationRevenueOpinionRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<ApplicationRevenueOpinionModel?>
      getByApplication(
      int applicationId) async {

    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "application_revenue_opinion",
          equals: {"applicationId": applicationId},
          limit: 1,
        );
        if (rows.isEmpty) return null;
        return ApplicationRevenueOpinionModel.fromMap(rows.first);
      } catch (e) {
        debugPrint('online getByApplication application_revenue_opinion failed, falling back to local: $e');
      }
    }

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

    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "application_revenue_opinion",
          equals: {"applicationId": item.applicationId},
          limit: 1,
        );
        if (rows.isEmpty) {
          await OnlineDatabase.insert(
            "application_revenue_opinion",
            item.toMap(),
          );
        } else {
          await OnlineDatabase.update(
            "application_revenue_opinion",
            (rows.first["id"] as num).toInt(),
            {
              "applicationId": item.applicationId,
              "revenueOpinionId": item.revenueOpinionId,
            },
          );
        }
        return;
      } catch (e) {
        if (e is StateError || e is ArgumentError) rethrow;
        debugPrint('online save application_revenue_opinion failed, falling back to local: $e');
      }
    }

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