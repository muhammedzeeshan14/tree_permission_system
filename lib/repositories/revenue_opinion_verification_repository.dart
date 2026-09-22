import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class RevenueOpinionVerificationRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<Map<String, dynamic>?> getVerification(
      int applicationId) async {

    if (OnlineMode.enabled) {
      try {
        final result = await OnlineDatabase.select(
          "revenue_opinion_verification",
          equals: {"applicationId": applicationId},
          limit: 1,
        );
        if (result.isEmpty) {
          return null;
        }
        return result.first;
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    final result = await db.query(

      "revenue_opinion_verification",

      where: "applicationId=?",

      whereArgs: [applicationId],

      limit: 1,

    );

    if (result.isEmpty) {

      return null;

    }

    return result.first;

  }

  Future<void> saveVerification({

    required int applicationId,

    required String verification,

    String? reason,

    String? verifiedBy,

  }) async {

    if (OnlineMode.enabled) {
      try {
        final values = <String, Object?>{

          "applicationId": applicationId,

          "verification": verification,

          "reason": reason,

          "verifiedBy": verifiedBy,

          "verifiedDate":
              DateTime.now().toIso8601String(),

        };
        await OnlineDatabase.delete(
          "revenue_opinion_verification",
          column: "applicationId",
          value: applicationId,
        );
        await OnlineDatabase.insert(
          "revenue_opinion_verification",
          values,
        );
        return;
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    final existing =
        await getVerification(applicationId);

    final values = {

      "applicationId": applicationId,

      "verification": verification,

      "reason": reason,

      "verifiedBy": verifiedBy,

      "verifiedDate":
          DateTime.now().toIso8601String(),

    };

    if (existing == null) {

      await db.insert(

        "revenue_opinion_verification",

        values,

      );

    } else {

      await db.update(

        "revenue_opinion_verification",

        values,

        where: "applicationId=?",

        whereArgs: [applicationId],

      );

    }

  }

}