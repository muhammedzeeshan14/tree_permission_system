import 'dart:io';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/photo_model.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class PhotoRepository {

  Future<Database> get _db async =>
      await DatabaseHelper.instance.database;

  // ======================================
  // SAVE PHOTO
  // ======================================

  Future<void> savePhoto(
    PhotoModel photo,
  ) async {

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.insert(
          "inspection_photos",
          {
            "applicationId": photo.applicationId,
            "photoPath": photo.photoPath,
            "caption": photo.caption,
            "createdDate": photo.createdDate,
          },
        );
        return;
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    await db.insert(

      "inspection_photos",

      {

        "applicationId": photo.applicationId,

        "photoPath": photo.photoPath,

        "caption": photo.caption,

        "createdDate": photo.createdDate,

      },

    );

  }

  // ======================================
  // GET PHOTOS
  // ======================================

  Future<List<PhotoModel>> getPhotos(
    int applicationId,
  ) async {

    if (OnlineMode.enabled) {
      try {
        final result = await OnlineDatabase.select(
          "inspection_photos",
          equals: {"applicationId": applicationId},
          orderBy: "id",
        );
        return result.map((row) {
          return PhotoModel(
            id: (row["id"] as num?)?.toInt() ?? 0,
            applicationId:
                (row["applicationId"] as num?)?.toInt() ?? 0,
            photoPath:
                row["photoPath"]?.toString() ?? "",
            caption:
                row["caption"]?.toString() ?? "",
            createdDate:
                row["createdDate"]?.toString() ?? "",
          );
        }).toList();
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    final result = await db.query(

      "inspection_photos",

      where: "applicationId=?",

      whereArgs: [applicationId],

      orderBy: "id ASC",

    );

    return result.map((row) {

      return PhotoModel(

        id: row["id"] as int,

        applicationId:
            row["applicationId"] as int,

        photoPath:
            row["photoPath"]?.toString() ?? "",

        caption:
            row["caption"]?.toString() ?? "",

        createdDate:
            row["createdDate"]?.toString() ?? "",

      );

    }).toList();

  }

  // ======================================
  // DELETE PHOTO
  // ======================================

  Future<void> deletePhoto(
  int photoId,
) async {

  if (OnlineMode.enabled) {
    try {
      final rows = await OnlineDatabase.select(
        "inspection_photos",
        equals: {"id": photoId},
        limit: 1,
      );

      if (rows.isNotEmpty) {
        final path =
            rows.first["photoPath"]?.toString() ?? "";

        if (path.isNotEmpty) {
          final file = File(path);

          if (await file.exists()) {
            await file.delete();
          }
        }
      }

      await OnlineDatabase.delete(
        "inspection_photos",
        column: "id",
        value: photoId,
      );
      return;
    } catch (_) {
      /* fall through to local */
    }
  }

  final db = await _db;

  final result = await db.query(

    "inspection_photos",

    where: "id=?",

    whereArgs: [photoId],

  );

  if (result.isNotEmpty) {

    final path =
        result.first["photoPath"]?.toString() ?? "";

    if (path.isNotEmpty) {

      final file = File(path);

      if (await file.exists()) {

        await file.delete();

      }

    }

  }

  await db.delete(

    "inspection_photos",

    where: "id=?",

    whereArgs: [photoId],

  );

}

  // ======================================
  // TOTAL PHOTOS
  // ======================================

  Future<int> totalPhotos(
    int applicationId,
  ) async {

    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "inspection_photos",
          equals: {"applicationId": applicationId},
        );
        return rows.length;
      } catch (_) {
        /* fall through to local */
      }
    }

    final db = await _db;

    final result = await db.rawQuery(

      """

SELECT COUNT(*) as total

FROM inspection_photos

WHERE applicationId=?

""",

      [applicationId],

    );

    return result.first["total"] as int;

  }

}