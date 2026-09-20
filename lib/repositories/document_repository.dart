import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/document_model.dart';

class DocumentRepository {

  Future<Database> get _db async =>
      await DatabaseHelper.instance.database;

  //=========================================
  // SAVE DOCUMENT
  //=========================================

  Future<void> saveDocument(
    DocumentModel document,
  ) async {

    final db = await _db;

    await db.insert(

      "inspection_documents",

      {

        "applicationId":
            document.applicationId,

        "documentName":
    document.documentTypeName,

        "filePath":
            document.filePath,

        "remarks":
            document.remarks,

        "createdDate":
            document.createdDate,

      },

    );

  }

  //=========================================
  // GET DOCUMENTS
  //=========================================

  Future<List<DocumentModel>> getDocuments(
    int applicationId,
  ) async {

    final db = await _db;

    final result = await db.query(

      "inspection_documents",

      where: "applicationId=?",

      whereArgs: [applicationId],

      orderBy: "id ASC",

    );

    return result.map((row) {

      return DocumentModel(

        id: row["id"] as int,

        applicationId:
            row["applicationId"] as int,

        documentTypeId: null,

        documentTypeName:
    row["documentName"]?.toString() ?? "",

        filePath:
            row["filePath"]
                    ?.toString() ??
                "",

        remarks:
            row["remarks"]
                    ?.toString() ??
                "",

        createdDate:
            row["createdDate"]
                    ?.toString() ??
                "",

      );

    }).toList();

  }

  //=========================================
  // DELETE DOCUMENT
  //=========================================

  Future<void> deleteDocument(
    int documentId,
  ) async {

    final db = await _db;

    final result = await db.query(

      "inspection_documents",

      where: "id=?",

      whereArgs: [documentId],

    );

    if (result.isNotEmpty) {

      final path =
          result.first["filePath"]
                  ?.toString() ??
              "";

      if (path.isNotEmpty) {

        final file = File(path);

        if (await file.exists()) {

          await file.delete();

        }

      }

    }

    await db.delete(

      "inspection_documents",

      where: "id=?",

      whereArgs: [documentId],

    );

  }

  //=========================================
  // TOTAL DOCUMENTS
  //=========================================

  Future<int> totalDocuments(
    int applicationId,
  ) async {

    final db = await _db;

    final result = await db.rawQuery(

      """

SELECT COUNT(*) AS total

FROM inspection_documents

WHERE applicationId=?

""",

      [applicationId],

    );

    return result.first["total"] as int;

  }

}