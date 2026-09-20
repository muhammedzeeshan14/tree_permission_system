import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

class RfoLetterConfigurationRepository {
  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<Map<String, String>>
      getAllLetterNumbers() async {
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