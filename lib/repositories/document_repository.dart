import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/document_model.dart';
import '../services/cloud_file_service.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class DocumentRepository {

  Future<Database> get _db async =>
      await DatabaseHelper.instance.database;

  //=========================================
  // SAVE DOCUMENT
  //=========================================

  Future<void> saveDocument(
    DocumentModel document,
  ) async {

    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.insert(
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
        return;
      } catch (_) {
        /* fall through to local */
      }
    }

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

    if (OnlineMode.enabled) {
      try {
        final result = await OnlineDatabase.select(
          "inspection_documents",
          equals: {"applicationId": applicationId},
          orderBy: "id",
        );
        final docs = result.map((row) {
          return DocumentModel(
            id: (row["id"] as num?)?.toInt() ?? 0,
            applicationId:
                (row["applicationId"] as num?)?.toInt() ?? 0,
            documentTypeId: null,
            documentTypeName:
                row["documentName"]?.toString() ?? "",
            filePath:
                row["filePath"]?.toString() ?? "",
            remarks:
                row["remarks"]?.toString() ?? "",
            createdDate:
                row["createdDate"]?.toString() ?? "",
          );
        }).toList();
        // Cloud: download bytes uploaded elsewhere; upload
        // local-only files from before cloud sync existed.
        try {
          final office =
              await CloudFileService.officeNumberFor(
            applicationId,
          );
          if (office.isNotEmpty) {
            final remote =
                await CloudFileService.listKeys(
              CloudFileService.docsBucket,
              'uploads/$office',
            );
            final remoteNames = remote
                .map((k) => k.split('/').last)
                .toSet();
            for (final doc in docs) {
              if (doc.filePath.isEmpty) continue;
              final file = File(doc.filePath);
              if (await file.exists()) {
                final name = doc.filePath
                    .split(RegExp(r'[/\\]'))
                    .last;
                if (!remoteNames.contains(name)) {
                  CloudFileService.uploadDocument(
                      office, file);
                }
              } else {
                await CloudFileService.ensureDocumentFile(
                  applicationId,
                  doc.filePath,
                );
              }
            }
          }
        } catch (_) {
          // Best effort only.
        }
        return docs;
      } catch (_) {
        /* fall through to local */
      }
    }

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

    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "inspection_documents",
          equals: {"id": documentId},
          limit: 1,
        );

        if (rows.isNotEmpty) {
          final path =
              rows.first["filePath"]?.toString() ?? "";

          if (path.isNotEmpty) {
            final file = File(path);

            if (await file.exists()) {
              await file.delete();
            }
          }
        }

        await OnlineDatabase.delete(
          "inspection_documents",
          column: "id",
          value: documentId,
        );
        return;
      } catch (_) {
        /* fall through to local */
      }
    }

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

    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "inspection_documents",
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

SELECT COUNT(*) AS total

FROM inspection_documents

WHERE applicationId=?

""",

      [applicationId],

    );

    return result.first["total"] as int;

  }

}