import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/photo_model.dart';
import '../services/cloud_file_service.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class PhotoRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<void> savePhoto(PhotoModel item) async {
    // Do not publish a record on other devices until the actual file is stored.
    final reference = await CloudFileService.savePhotoFile(item.applicationId, item.storedPath);
    final row = <String, Object?>{'applicationId': item.applicationId, 'photoPath': reference,
      "caption": item.caption, 'createdDate': item.createdDate};
    if (OnlineMode.enabled) {
      final existing = await OnlineDatabase.select('inspection_photos', equals: {'applicationId': item.applicationId, 'photoPath': reference}, limit: 1);
      item.id = existing.isEmpty ? await OnlineDatabase.insert('inspection_photos', row) : (existing.first['id'] as num).toInt();
      item.sourcePath = reference;
      return;
    }
    final db = await _db;
    item.id = await db.insert('inspection_photos', row);
  }

  Future<List<PhotoModel>> getPhotos(int applicationId) async {
    final List<Map<String, dynamic>> rows;
    if (OnlineMode.enabled) {
      rows = await OnlineDatabase.selectAll('inspection_photos', equals: {'applicationId': applicationId}, orderBy: 'id');
    } else {
      final db = await _db;
      rows = await db.query('inspection_photos', where: 'applicationId=?', whereArgs: [applicationId], orderBy: 'id ASC');
    }
    final office = rows.isEmpty ? '' : await CloudFileService.officeNumberFor(applicationId);
    final items = <PhotoModel>[];
    for (var offset = 0; offset < rows.length; offset += 3) {
      items.addAll(await Future.wait(rows.skip(offset).take(3).map((row) async {
      final original = row['photoPath']?.toString() ?? '';
      final item = PhotoModel(id: (row['id'] as num?)?.toInt(), applicationId: applicationId,
        photoPath: original, caption: row['caption']?.toString() ?? '', createdDate: row['createdDate']?.toString() ?? '')..sourcePath = original;
      try {
        item.photoPath = await CloudFileService.resolvePhotoPath(applicationId: applicationId, storedPath: original, officeNumber: office, requiredForUse: true);
      } catch (error) {
        // Keep the record visible, with a retryable error instead of dropping it.
        item.attachmentError = error.toString();
      }
      return item;
      })));
    }
    return items;
  }

  Future<void> deletePhoto(int id) async {
    if (OnlineMode.enabled) {
      await OnlineDatabase.delete('inspection_photos', column: 'id', value: id);
      return;
    }
    final db = await _db;
    await db.delete('inspection_photos', where: 'id=?', whereArgs: [id]);
  }

  Future<int> totalPhotos(int applicationId) async {
    if (OnlineMode.enabled) {
      return (await OnlineDatabase.selectAll('inspection_photos', equals: {'applicationId': applicationId})).length;
    }
    final db = await _db;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM inspection_photos WHERE applicationId=?', [applicationId])) ?? 0;
  }
}
