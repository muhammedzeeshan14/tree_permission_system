import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class OfficeConfigurationRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<Map<String, dynamic>?> getConfiguration() async {

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