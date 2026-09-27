import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/cloud_file_service.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class InspectionPhotoRepository {

  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  //==================================
  // GET PHOTOS
  //==================================

  Future<List<Map<String,dynamic>>> getPhotos(

      int applicationId,

  ) async {

    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "inspection_photos",
          equals: {"applicationId": applicationId},
          orderBy: "id",
        );
        // Cloud: fetch bytes taken on other devices, remapped
        // to this device's photo folder.
        for (final row in rows) {
          row["photoPath"] =
              await CloudFileService.resolvePhotoPath(
            applicationId: applicationId,
            storedPath: row["photoPath"]?.toString() ?? "",
          );
        }
        return rows;
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    final rows = await db.query(

      "inspection_photos",

      where: "applicationId=?",

      whereArgs: [

        applicationId,

      ],

      orderBy: "id",

    );

    for (final row in rows) {
      row["photoPath"] =
          await CloudFileService.resolvePhotoPath(
        applicationId: applicationId,
        storedPath: row["photoPath"]?.toString() ?? "",
      );
    }

    return rows;

  }

  //==================================
  // INSERT PHOTO
  //==================================

  Future<int> insertPhoto(

      Map<String,dynamic> data,

  ) async {

    if (OnlineMode.enabled) {
      try {
        return await OnlineDatabase.insert(
          "inspection_photos",
          data,
        );
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    return await db.insert(

      "inspection_photos",

      data,

    );

  }

  //==================================
  // DELETE PHOTO
  //==================================

  Future<void> deletePhoto(

      int id,

  ) async {

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(
          "inspection_photos",
          column: "id",
          value: id,
        );
        return;
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    await db.delete(

      "inspection_photos",

      where: "id=?",

      whereArgs: [

        id,

      ],

    );

  }

}