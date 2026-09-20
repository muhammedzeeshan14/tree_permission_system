import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class RfoDeferredLetterRecipient {
  final String recipientKey;
  final int? sourceId;
  final String recipientText;
  final bool isPrimary;
  final int displayOrder;

  const RfoDeferredLetterRecipient({
    required this.recipientKey,
    required this.sourceId,
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
    required RfoDeferredLetterRecipient
        primaryRecipient,
    required List<RfoDeferredLetterRecipient>
        copyRecipients,
  }) async {
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