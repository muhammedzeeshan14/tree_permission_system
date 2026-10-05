import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../models/document_model.dart';
import '../services/cloud_file_service.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class DocumentRepository {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  Future<void> saveDocument(DocumentModel item) async {
    // Do not publish a record on other devices until the actual file is stored.
    final reference = await CloudFileService.saveDocumentFile(item.applicationId, item.storedPath);
    final row = <String, Object?>{'applicationId': item.applicationId, 'filePath': reference,
      "documentName": item.documentTypeName, "remarks": item.remarks, 'createdDate': item.createdDate};
    if (OnlineMode.enabled) {
      final existing = await OnlineDatabase.select('inspection_documents', equals: {'applicationId': item.applicationId, 'filePath': reference}, limit: 1);
      item.id = existing.isEmpty ? await OnlineDatabase.insert('inspection_documents', row) : (existing.first['id'] as num).toInt();
      item.sourcePath = reference;
      return;
    }
    final db = await _db;
    item.id = await db.insert('inspection_documents', row);
  }

  Future<List<DocumentModel>> getDocuments(int applicationId) async {
    final List<Map<String, dynamic>> rows;
    if (OnlineMode.enabled) {
      rows = await OnlineDatabase.selectAll('inspection_documents', equals: {'applicationId': applicationId}, orderBy: 'id');
    } else {
      final db = await _db;
      rows = await db.query('inspection_documents', where: 'applicationId=?', whereArgs: [applicationId], orderBy: 'id ASC');
    }
    final office = rows.isEmpty ? '' : await CloudFileService.officeNumberFor(applicationId);
    final items = <DocumentModel>[];
    for (var offset = 0; offset < rows.length; offset += 3) {
      items.addAll(await Future.wait(rows.skip(offset).take(3).map((row) async {
      final original = row['filePath']?.toString() ?? '';
      final item = DocumentModel(id: (row['id'] as num?)?.toInt(), applicationId: applicationId,
        filePath: original, documentTypeId: null, documentTypeName: row['documentName']?.toString() ?? '', remarks: row['remarks']?.toString() ?? '', createdDate: row['createdDate']?.toString() ?? '')..sourcePath = original;
      try {
        item.filePath = await CloudFileService.resolveDocumentPath(applicationId: applicationId, storedPath: original, officeNumber: office, requiredForUse: true);
        if (OnlineMode.enabled && !original.startsWith('cloud://')) {
          final portable = await CloudFileService.saveDocumentFile(applicationId, item.filePath);
          await OnlineDatabase.update('inspection_documents', item.id!, {'filePath': portable});
          item.sourcePath = portable;
        }
      } catch (error) {
        // Keep the record visible, with a retryable error instead of dropping it.
        item.attachmentError = error.toString();
      }
      return item;
      })));
    }
    return items;
  }

  Future<void> deleteDocument(int id) async {
    if (OnlineMode.enabled) {
      await OnlineDatabase.delete('inspection_documents', column: 'id', value: id);
      return;
    }
    final db = await _db;
    await db.delete('inspection_documents', where: 'id=?', whereArgs: [id]);
  }

  Future<int> totalDocuments(int applicationId) async {
    if (OnlineMode.enabled) {
      return (await OnlineDatabase.selectAll('inspection_documents', equals: {'applicationId': applicationId})).length;
    }
    final db = await _db;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM inspection_documents WHERE applicationId=?', [applicationId])) ?? 0;
  }
}
