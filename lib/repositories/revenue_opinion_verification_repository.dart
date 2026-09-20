import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class RevenueOpinionVerificationRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<Map<String, dynamic>?> getVerification(
      int applicationId) async {

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