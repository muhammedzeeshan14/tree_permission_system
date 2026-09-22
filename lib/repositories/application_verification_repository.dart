import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';

class ApplicationVerificationRepository {
  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<void> saveVerification({
    required int applicationId,
    bool? applicationTypeCorrect,
    String? applicationTypeReason,
    bool? governmentAgencyCorrect,
String? governmentAgencyReason,

bool? urbanRuralCorrect,
String? urbanRuralReason,

bool? whyRemovingCorrect,
String? whyRemovingReason,

bool? purposeCorrect,
String? purposeReason,

bool? structureTypeCorrect,
String? structureTypeReason,

bool? workNameCorrect,
String? workNameReason,

bool? overallRemarkCorrect,
String? overallRemarkReason,

    bool? gpsCorrect,
    String? gpsReason,
    bool? photosCorrect,
    String? photosReason,
    bool? documentsCorrect,
    String? documentsReason,

    String? applicationTypeStatus,
String? governmentAgencyStatus,
String? urbanRuralStatus,
String? whyRemovingStatus,
String? purposeStatus,
String? structureTypeStatus,
String? workNameStatus,
String? overallRemarkStatus,
String? gpsStatus,
String? photosStatus,
String? documentsStatus,
    required String verifiedBy,
  }) async {
    if (OnlineMode.enabled) {
      try {
        final row = <String, Object?>{
          "applicationId": applicationId,
          "applicationTypeCorrect":
              applicationTypeCorrect == null
                  ? null
                  : applicationTypeCorrect
                      ? 1
                      : 0,
          "applicationTypeReason": applicationTypeReason,
          "governmentAgencyCorrect":
              governmentAgencyCorrect == null
                  ? null
                  : governmentAgencyCorrect
                      ? 1
                      : 0,
          "governmentAgencyReason": governmentAgencyReason,
          "urbanRuralCorrect":
              urbanRuralCorrect == null
                  ? null
                  : urbanRuralCorrect
                      ? 1
                      : 0,
          "urbanRuralReason": urbanRuralReason,
          "whyRemovingCorrect":
              whyRemovingCorrect == null
                  ? null
                  : whyRemovingCorrect
                      ? 1
                      : 0,
          "whyRemovingReason": whyRemovingReason,
          "purposeCorrect":
              purposeCorrect == null
                  ? null
                  : purposeCorrect
                      ? 1
                      : 0,
          "purposeReason": purposeReason,
          "structureTypeCorrect":
              structureTypeCorrect == null
                  ? null
                  : structureTypeCorrect
                      ? 1
                      : 0,
          "structureTypeReason": structureTypeReason,
          "workNameCorrect":
              workNameCorrect == null
                  ? null
                  : workNameCorrect
                      ? 1
                      : 0,
          "workNameReason": workNameReason,
          "overallRemarkCorrect":
              overallRemarkCorrect == null
                  ? null
                  : overallRemarkCorrect
                      ? 1
                      : 0,
          "overallRemarkReason": overallRemarkReason,
          "gpsCorrect": gpsCorrect == null
              ? null
              : gpsCorrect
                  ? 1
                  : 0,
          "gpsReason": gpsReason,
          "photosCorrect": photosCorrect == null
              ? null
              : photosCorrect
                  ? 1
                  : 0,
          "photosReason": photosReason,
          "documentsCorrect": documentsCorrect == null
              ? null
              : documentsCorrect
                  ? 1
                  : 0,
          "documentsReason": documentsReason,
          "applicationTypeStatus": applicationTypeStatus,
          "governmentAgencyStatus": governmentAgencyStatus,
          "urbanRuralStatus": urbanRuralStatus,
          "whyRemovingStatus": whyRemovingStatus,
          "purposeStatus": purposeStatus,
          "structureTypeStatus": structureTypeStatus,
          "workNameStatus": workNameStatus,
          "overallRemarkStatus": overallRemarkStatus,
          "gpsStatus": gpsStatus,
          "photosStatus": photosStatus,
          "documentsStatus": documentsStatus,
          "verifiedBy": verifiedBy,
        };
        await OnlineDatabase.delete(
          "application_verifications",
          column: "applicationId",
          value: applicationId,
        );
        await OnlineDatabase.insert(
          "application_verifications",
          row,
        );
        return;
      } catch (_) {
        /* fall through to local */
      }
    }
    final db = await _db;

    await db.insert(
      "application_verifications",
      {
        "applicationId": applicationId,
       "applicationTypeCorrect":
    applicationTypeCorrect == null
        ? null
        : applicationTypeCorrect
            ? 1
            : 0,
        "applicationTypeReason": applicationTypeReason,
        "governmentAgencyCorrect":
    governmentAgencyCorrect == null
        ? null
        : governmentAgencyCorrect
            ? 1
            : 0,

"governmentAgencyReason":
    governmentAgencyReason,

"urbanRuralCorrect":
    urbanRuralCorrect == null
        ? null
        : urbanRuralCorrect
            ? 1
            : 0,

"urbanRuralReason":
    urbanRuralReason,

    "whyRemovingCorrect":
    whyRemovingCorrect == null
        ? null
        : whyRemovingCorrect
            ? 1
            : 0,

"whyRemovingReason":
    whyRemovingReason,

"purposeCorrect":
    purposeCorrect == null
        ? null
        : purposeCorrect
            ? 1
            : 0,

"purposeReason":
    purposeReason,

"structureTypeCorrect":
    structureTypeCorrect == null
        ? null
        : structureTypeCorrect
            ? 1
            : 0,

"structureTypeReason":
    structureTypeReason,

"workNameCorrect":
    workNameCorrect == null
        ? null
        : workNameCorrect
            ? 1
            : 0,

"workNameReason":
    workNameReason,

"overallRemarkCorrect":
    overallRemarkCorrect == null
        ? null
        : overallRemarkCorrect
            ? 1
            : 0,

"overallRemarkReason":
    overallRemarkReason,

       "gpsCorrect": gpsCorrect == null
    ? null
    : gpsCorrect
        ? 1
        : 0,
        "gpsReason": gpsReason,
        "photosCorrect": photosCorrect == null
    ? null
    : photosCorrect
        ? 1
        : 0,
        "photosReason": photosReason,
        "documentsCorrect": documentsCorrect == null
    ? null
    : documentsCorrect
        ? 1
        : 0,
        "documentsReason": documentsReason,

        "applicationTypeStatus":
    applicationTypeStatus,

"governmentAgencyStatus":
    governmentAgencyStatus,

"urbanRuralStatus":
    urbanRuralStatus,

"whyRemovingStatus":
    whyRemovingStatus,

"purposeStatus":
    purposeStatus,

"structureTypeStatus":
    structureTypeStatus,

"workNameStatus":
    workNameStatus,

"overallRemarkStatus":
    overallRemarkStatus,

"gpsStatus":
    gpsStatus,

"photosStatus":
    photosStatus,

"documentsStatus":
    documentsStatus,
        "verifiedBy": verifiedBy,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getVerification(
      int applicationId) async {
    if (OnlineMode.enabled) {
      try {
        final result = await OnlineDatabase.select(
          "application_verifications",
          equals: {"applicationId": applicationId},
          limit: 1,
        );
        if (result.isEmpty) {
          return null;
        }
        return result.first;
      } catch (_) {
        /* fall through to local */
      }
    }
    final db = await _db;

    final result = await db.query(
      "application_verifications",
      where: "applicationId=?",
      whereArgs: [applicationId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }
}