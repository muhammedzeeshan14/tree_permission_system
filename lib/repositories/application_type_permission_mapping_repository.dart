import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class ApplicationTypePermissionMappingRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<List<Map<String, dynamic>>> getAll() async {

    if (OnlineMode.enabled) {
      try {
        final mappings = await OnlineDatabase.select(
          "application_type_permission_mapping",
        );
        final appTypes = await OnlineDatabase.select(
          "application_type_master",
        );
        final permTypes = await OnlineDatabase.select(
          "permission_type_master",
        );
        final appById = <int, Map<String, dynamic>>{
          for (final a in appTypes)
            if ((a['id'] as num?) != null)
              (a['id'] as num).toInt(): a,
        };
        final permById = <int, Map<String, dynamic>>{
          for (final p in permTypes)
            if ((p['id'] as num?) != null)
              (p['id'] as num).toInt(): p,
        };
        final joined = [
          for (final m in mappings)
            {
              "id": m["id"],
              "applicationTypeId": m["applicationTypeId"],
              "permissionTypeId": m["permissionTypeId"],
              "applicationType": appById[
                  (m["applicationTypeId"] as num?)?.toInt()]?["applicationType"],
              "permissionType": permById[
                  (m["permissionTypeId"] as num?)?.toInt()]?["permissionType"],
            },
        ];
        joined.sort((a, b) {
          final orderA = (appById[(a["applicationTypeId"] as num?)?.toInt()]?["displayOrder"] as num?)?.toInt() ?? 0;
          final orderB = (appById[(b["applicationTypeId"] as num?)?.toInt()]?["displayOrder"] as num?)?.toInt() ?? 0;
          return orderA.compareTo(orderB);
        });
        return joined;
      } catch (e) {
        debugPrint('online getAll application_type_permission_mapping failed, falling back to local: $e');
      }
    }

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

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(
          "application_type_permission_mapping",
          column: "applicationTypeId",
          value: applicationTypeId,
        );
        await OnlineDatabase.insert(
          "application_type_permission_mapping",
          {
            "applicationTypeId": applicationTypeId,
            "permissionTypeId": permissionTypeId,
          },
        );
        return;
      } catch (e) {
        debugPrint('online saveMapping application_type_permission_mapping failed, falling back to local: $e');
      }
    }

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

    if (OnlineMode.enabled) {
      try {
        final mappings = await OnlineDatabase.select(
          "application_type_permission_mapping",
          equals: {"applicationTypeId": applicationTypeId},
          limit: 1,
        );
        if (mappings.isEmpty) return null;
        final permissionTypeId =
            (mappings.first["permissionTypeId"] as num?)?.toInt();
        if (permissionTypeId == null) return null;
        final perms = await OnlineDatabase.select(
          "permission_type_master",
          equals: {"id": permissionTypeId},
          limit: 1,
        );
        if (perms.isEmpty) return null;
        return {
          "id": perms.first["id"],
          "permissionType": perms.first["permissionType"],
        };
      } catch (e) {
        debugPrint('online getPermissionForApplicationType failed, falling back to local: $e');
      }
    }

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
