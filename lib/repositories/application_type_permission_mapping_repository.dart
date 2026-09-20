import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class ApplicationTypePermissionMappingRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<List<Map<String, dynamic>>> getAll() async {

    final db = await _db;

    return await db.rawQuery("""

SELECT

m.id,

m.applicationTypeId,

m.permissionTypeId,

a.applicationType,

p.permissionType

FROM application_type_permission_mapping m

LEFT JOIN application_type_master a

ON a.id = m.applicationTypeId

LEFT JOIN permission_type_master p

ON p.id = m.permissionTypeId

ORDER BY a.displayOrder

""");

  }

  Future<void> saveMapping({

    required int applicationTypeId,

    required int permissionTypeId,

  }) async {

    final db = await _db;

    await db.delete(

      "application_type_permission_mapping",

      where: "applicationTypeId=?",

      whereArgs: [applicationTypeId],

    );

    await db.insert(

      "application_type_permission_mapping",

      {

        "applicationTypeId": applicationTypeId,

        "permissionTypeId": permissionTypeId,

      },

    );

  }

  Future<Map<String, dynamic>?> getPermissionForApplicationType(
      int applicationTypeId) async {

    final db = await _db;

    final result = await db.rawQuery("""

SELECT

p.id,

p.permissionType

FROM application_type_permission_mapping m

LEFT JOIN permission_type_master p

ON p.id=m.permissionTypeId

WHERE m.applicationTypeId=?

LIMIT 1

""", [

      applicationTypeId,

    ]);

    if (result.isEmpty) return null;

    return result.first;

  }

}