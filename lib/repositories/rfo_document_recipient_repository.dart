import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class RfoDocumentRecipient {
  final String recipientKey;
  final String recipientText;
  final bool isPrimary;
  final int displayOrder;

  const RfoDocumentRecipient({
    required this.recipientKey,
    required this.recipientText,
    required this.isPrimary,
    required this.displayOrder,
  });
}

class RfoDocumentRecipientRepository {
  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<List<RfoDocumentRecipient>>
      getRecipients({
    required int applicationId,
    required String documentCode,
  }) async {
    final db = await _db;

    final rows = await db.query(
      "rfo_document_recipients",
      where:
          "applicationId = ? AND documentCode = ?",
      whereArgs: [
        applicationId,
        documentCode,
      ],
      orderBy:
          "isPrimary DESC, displayOrder ASC, id ASC",
    );

    return rows.map((row) {
      return RfoDocumentRecipient(
        recipientKey:
            row["recipientKey"]?.toString() ?? "",
        recipientText:
            row["recipientText"]?.toString() ?? "",
        isPrimary:
            (row["isPrimary"] as int? ?? 0) == 1,
        displayOrder:
            row["displayOrder"] as int? ?? 0,
      );
    }).toList();
  }

  Future<void> saveRecipients({
    required int applicationId,
    required String documentCode,
    required RfoDocumentRecipient primaryRecipient,
    required List<RfoDocumentRecipient> copyRecipients,
  }) async {
    final db = await _db;

    await db.transaction((transaction) async {
      await transaction.delete(
        "rfo_document_recipients",
        where:
            "applicationId = ? AND documentCode = ?",
        whereArgs: [
          applicationId,
          documentCode,
        ],
      );

      await transaction.insert(
        "rfo_document_recipients",
        {
          "applicationId": applicationId,
          "documentCode": documentCode,
          "recipientKey":
              primaryRecipient.recipientKey,
          "recipientText":
              primaryRecipient.recipientText,
          "isPrimary": 1,
          "displayOrder": 0,
        },
      );

      for (int index = 0;
          index < copyRecipients.length;
          index++) {
        final recipient = copyRecipients[index];

        await transaction.insert(
          "rfo_document_recipients",
          {
            "applicationId": applicationId,
            "documentCode": documentCode,
            "recipientKey":
                recipient.recipientKey,
            "recipientText":
                recipient.recipientText,
            "isPrimary": 0,
            "displayOrder": index + 1,
          },
        );
      }
    });
  }
}