import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

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

    final db = await _db;

    return await db.query(

      "inspection_photos",

      where: "applicationId=?",

      whereArgs: [

        applicationId,

      ],

      orderBy: "id",

    );

  }

  //==================================
  // INSERT PHOTO
  //==================================

  Future<int> insertPhoto(

      Map<String,dynamic> data,

  ) async {

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