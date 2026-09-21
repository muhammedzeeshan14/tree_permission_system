import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class OfficeConfigurationRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<Map<String, dynamic>?> getConfiguration() async {

    if (OnlineMode.enabled) {
      try {
        final result = await OnlineDatabase.select(
          "office_configuration",
          limit: 1,
        );
        if (result.isEmpty) {
          return null;
        }
        return result.first;
      } catch (e) {
        debugPrint('online getConfiguration office_configuration failed, falling back to local: $e');
      }
    }

    final db = await _db;

    final result =
        await db.query("office_configuration");

    if (result.isEmpty) {

      return null;

    }

    return result.first;

  }

  Future<void> saveConfiguration({

   required String rangeName,

required String rangeLocation,

required String rangeCode,
    required String officePrefix,

    required String financialYear,

    required String rangeOfficeAddress,

required String rangeEmail,
required String rfoOfficeLogoPath,
required String division,
    required String subDivision,

  }) async {

    if (OnlineMode.enabled) {
      try {
        final existing = await OnlineDatabase.select("office_configuration");
        final row = {
          "rangeName": rangeName,
          "rangeLocation": rangeLocation,
          "rangeCode": rangeCode,
          "officePrefix": officePrefix,
          "financialYear": financialYear,
          "rangeOfficeAddress": rangeOfficeAddress,
          "rangeEmail": rangeEmail,
          "rfoOfficeLogoPath": rfoOfficeLogoPath,
          "division": division,
          "subDivision": subDivision,
        };
        if (existing.isEmpty) {
          await OnlineDatabase.insert(
            "office_configuration",
            row,
          );
        } else {
          await OnlineDatabase.update(
            "office_configuration",
            (existing.first["id"] as num).toInt(),
            row,
          );
        }
        return;
      } catch (e) {
        debugPrint('online saveConfiguration office_configuration failed, falling back to local: $e');
      }
    }

    final db = await _db;

    final existing =
        await db.query("office_configuration");

    if (existing.isEmpty) {

      await db.insert(

        "office_configuration",

        {

          "rangeName": rangeName,

"rangeLocation": rangeLocation,

"rangeCode": rangeCode,

          "officePrefix": officePrefix,

          "financialYear": financialYear,

          "rangeOfficeAddress":
    rangeOfficeAddress,

"rangeEmail": rangeEmail,
"rfoOfficeLogoPath": rfoOfficeLogoPath,
"division": division,

          "subDivision": subDivision,

        },

      );

    } else {

      await db.update(

        "office_configuration",

        {

         "rangeName": rangeName,

"rangeLocation": rangeLocation,

"rangeCode": rangeCode,

          "officePrefix": officePrefix,

          "financialYear": financialYear,

          "rangeOfficeAddress":
    rangeOfficeAddress,

"rangeEmail": rangeEmail,
"rfoOfficeLogoPath": rfoOfficeLogoPath,
"division": division,

          "subDivision": subDivision,

        },

        where: "id=?",

        whereArgs: [existing.first["id"]],

      );

    }

  }

}
