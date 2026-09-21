import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class RfoLetterConfigurationRepository {
  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<Map<String, String>>
      getAllLetterNumbers() async {
    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "rfo_letter_configuration",
          orderBy: "applicationTypeCode",
        );
        return {
          for (final row in rows)
            row["applicationTypeCode"]
                    ?.toString()
                    .trim()
                    .toUpperCase() ??
                "":
                row["letterNumber"]
                        ?.toString()
                        .trim() ??
                    "",
        };
      } catch (e) {
        debugPrint('online getAllLetterNumbers rfo_letter_configuration failed, falling back to local: $e');
      }
    }
    final db = await _db;

    final rows = await db.query(
      "rfo_letter_configuration",
      orderBy: "applicationTypeCode ASC",
    );

    return {
      for (final row in rows)
        row["applicationTypeCode"]
                ?.toString()
                .trim()
                .toUpperCase() ??
            "":
            row["letterNumber"]
                    ?.toString()
                    .trim() ??
                "",
    };
  }

  Future<String> getLetterNumber(
    String applicationTypeCode,
  ) async {
    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          "rfo_letter_configuration",
          equals: {
            "applicationTypeCode":
                applicationTypeCode.trim().toUpperCase(),
          },
          limit: 1,
        );
        if (rows.isEmpty) {
          return "";
        }
        return rows.first["letterNumber"]
                ?.toString()
                .trim() ??
            "";
      } catch (e) {
        debugPrint('online getLetterNumber rfo_letter_configuration failed, falling back to local: $e');
      }
    }
    final db = await _db;

    final rows = await db.query(
      "rfo_letter_configuration",
      columns: ["letterNumber"],
      where: "applicationTypeCode = ?",
      whereArgs: [
        applicationTypeCode
            .trim()
            .toUpperCase(),
      ],
      limit: 1,
    );

    if (rows.isEmpty) {
      return "";
    }

    return rows.first["letterNumber"]
            ?.toString()
            .trim() ??
        "";
  }

  Future<void> saveLetterNumber({
    required String applicationTypeCode,
    required String letterNumber,
  }) async {
    if (OnlineMode.enabled) {
      try {
        final code =
            applicationTypeCode.trim().toUpperCase();
        final existing = await OnlineDatabase.select(
          "rfo_letter_configuration",
          equals: {"applicationTypeCode": code},
          limit: 1,
        );
        if (existing.isEmpty) {
          await OnlineDatabase.insert(
            "rfo_letter_configuration",
            {
              "applicationTypeCode": code,
              "letterNumber": letterNumber.trim(),
            },
          );
        } else {
          await OnlineDatabase.update(
            "rfo_letter_configuration",
            (existing.first["id"] as num).toInt(),
            {
              "applicationTypeCode": code,
              "letterNumber": letterNumber.trim(),
            },
          );
        }
        return;
      } catch (e) {
        debugPrint('online saveLetterNumber rfo_letter_configuration failed, falling back to local: $e');
      }
    }
    final db = await _db;

    await db.insert(
      "rfo_letter_configuration",
      {
        "applicationTypeCode":
            applicationTypeCode
                .trim()
                .toUpperCase(),
        "letterNumber":
            letterNumber.trim(),
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace,
    );
  }
}
