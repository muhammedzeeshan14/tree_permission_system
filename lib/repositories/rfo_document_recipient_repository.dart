import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

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
    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "rfo_document_recipients",
          equals: {
            "applicationId": applicationId,
            "documentCode": documentCode,
          },
        );
        rows.sort((a, b) {
          final primary = (((b["isPrimary"] as num?)?.toInt() ?? 0))
              .compareTo((a["isPrimary"] as num?)?.toInt() ?? 0);
          if (primary != 0) return primary;
          final order = (((a["displayOrder"] as num?)?.toInt() ?? 0))
              .compareTo((b["displayOrder"] as num?)?.toInt() ?? 0);
          if (order != 0) return order;
          return (((a["id"] as num?)?.toInt() ?? 0))
              .compareTo((b["id"] as num?)?.toInt() ?? 0);
        });
        return rows.map(_fromRow).toList();
      } catch (e) {
        debugPrint('online getRecipients rfo_document_recipients failed, falling back to local: $e');
      }
    }
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

  static RfoDocumentRecipient _fromRow(
    Map<String, dynamic> row,
  ) {
    return RfoDocumentRecipient(
      recipientKey:
          row["recipientKey"]?.toString() ?? "",
      recipientText:
          row["recipientText"]?.toString() ?? "",
      isPrimary:
          ((row["isPrimary"] as num?)?.toInt() ?? 0) == 1,
      displayOrder:
          (row["displayOrder"] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> saveRecipients({
    required int applicationId,
    required String documentCode,
    required RfoDocumentRecipient primaryRecipient,
    required List<RfoDocumentRecipient> copyRecipients,
  }) async {
    if (OnlineMode.enabled) {
      try {
        final existing = await OnlineDatabase.select(
          "rfo_document_recipients",
          equals: {
            "applicationId": applicationId,
            "documentCode": documentCode,
          },
        );
        for (final row in existing) {
          await OnlineDatabase.delete(
            "rfo_document_recipients",
            column: "id",
            value: (row["id"] as num).toInt(),
          );
        }

        await OnlineDatabase.insert(
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

          await OnlineDatabase.insert(
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
        return;
      } catch (e) {
        debugPrint('online saveRecipients rfo_document_recipients failed, falling back to local: $e');
      }
    }
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