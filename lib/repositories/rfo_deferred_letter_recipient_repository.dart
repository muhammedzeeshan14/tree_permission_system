import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class RfoDeferredLetterRecipient {
  final String recipientKey;
  final int? sourceId;
  final String sourceKind; // SOURCE | AGENCY | OFFICER
  final String recipientText;
  final bool isPrimary;
  final int displayOrder;

  const RfoDeferredLetterRecipient({
    required this.recipientKey,
    required this.sourceId,
    this.sourceKind = 'SOURCE',
    required this.recipientText,
    required this.isPrimary,
    required this.displayOrder,
  });
}

class RfoDeferredLetterRecipientRepository {
  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<List<RfoDeferredLetterRecipient>>
      getRecipients(int applicationId) async {
    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "rfo_deferred_letter_recipients",
          equals: {"applicationId": applicationId},
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
        debugPrint('online getRecipients rfo_deferred_letter_recipients failed, falling back to local: $e');
      }
    }
    final db = await _db;

    final rows = await db.query(
      "rfo_deferred_letter_recipients",
      where: "applicationId = ?",
      whereArgs: [applicationId],
      orderBy:
          "isPrimary DESC, displayOrder ASC, id ASC",
    );

    return rows.map((row) {
      return RfoDeferredLetterRecipient(
        recipientKey:
            row["recipientKey"]?.toString() ?? "",
        sourceId:
            row["sourceId"] as int?,
        sourceKind:
            row["sourceKind"]?.toString() ?? "SOURCE",
        recipientText:
            row["recipientText"]?.toString() ?? "",
        isPrimary:
            (row["isPrimary"] as int? ?? 0) == 1,
        displayOrder:
            row["displayOrder"] as int? ?? 0,
      );
    }).toList();
  }

  static RfoDeferredLetterRecipient _fromRow(
    Map<String, dynamic> row,
  ) {
    return RfoDeferredLetterRecipient(
      recipientKey:
          row["recipientKey"]?.toString() ?? "",
      sourceId:
          (row["sourceId"] as num?)?.toInt(),
      sourceKind:
          row["sourceKind"]?.toString() ?? "SOURCE",
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
    required RfoDeferredLetterRecipient
        primaryRecipient,
    required List<RfoDeferredLetterRecipient>
        copyRecipients,
  }) async {
    if (OnlineMode.enabled) {
      try {
        await OnlineDatabase.delete(
          "rfo_deferred_letter_recipients",
          column: "applicationId",
          value: applicationId,
        );

        await OnlineDatabase.insert(
          "rfo_deferred_letter_recipients",
          {
            "applicationId": applicationId,
            "recipientKey":
                primaryRecipient.recipientKey,
            "sourceId":
                primaryRecipient.sourceId,
            "sourceKind":
                primaryRecipient.sourceKind,
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
            "rfo_deferred_letter_recipients",
            {
              "applicationId": applicationId,
              "recipientKey":
                  recipient.recipientKey,
              "sourceId":
                  recipient.sourceId,
              "sourceKind":
                  recipient.sourceKind,
              "recipientText":
                  recipient.recipientText,
              "isPrimary": 0,
              "displayOrder": index + 1,
            },
          );
        }
        return;
      } catch (e) {
        debugPrint('online saveRecipients rfo_deferred_letter_recipients failed, falling back to local: $e');
      }
    }
    final db = await _db;

    await db.transaction((transaction) async {
      await transaction.delete(
        "rfo_deferred_letter_recipients",
        where: "applicationId = ?",
        whereArgs: [applicationId],
      );

      await transaction.insert(
        "rfo_deferred_letter_recipients",
        {
          "applicationId": applicationId,
          "recipientKey":
              primaryRecipient.recipientKey,
          "sourceId":
              primaryRecipient.sourceId,
          "sourceKind":
              primaryRecipient.sourceKind,
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
          "rfo_deferred_letter_recipients",
          {
            "applicationId": applicationId,
            "recipientKey":
                recipient.recipientKey,
            "sourceId":
                recipient.sourceId,
            "sourceKind":
                recipient.sourceKind,
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