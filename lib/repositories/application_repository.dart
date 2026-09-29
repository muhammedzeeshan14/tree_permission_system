import 'user_repository.dart';
import 'revenue_reply_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/application_model.dart';
import '../models/application_reference_model.dart';
import '../constants/workflow_status.dart';
import '../services/office_number_service.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';
import '../services/sync_service.dart';

class ApplicationRepository {
  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  // ======================================
  // OFFICE NUMBER UNIQUENESS (online + local)
  // ======================================

  Future<bool> _officeNumberTaken(String officeNumber) async {
    if (officeNumber.trim().isEmpty) return true;
    if (OnlineMode.enabled) {
      try {
        final rows = await OnlineDatabase.select(
          'applications',
          equals: {'officeNumber': officeNumber.trim()},
          limit: 1,
        );
        if (rows.isNotEmpty) return true;
      } catch (e) {
        debugPrint('office number online check failed: $e');
      }
    }
    try {
      final db = await _db;
      final rows = await db.query(
        'applications',
        columns: ['id'],
        where: 'officeNumber=?',
        whereArgs: [officeNumber.trim()],
        limit: 1,
      );
      if (rows.isNotEmpty) return true;
    } catch (e) {
      debugPrint('office number local check failed: $e');
    }
    return false;
  }

  // ======================================
  // INSERT APPLICATION
  // ======================================

  Future<int> insertApplication(
    ApplicationModel application) async {

  // The office number is reserved when the entry form opens, so two
  // devices can hold the same number (offline reserve, discarded
  // forms). Guarantee uniqueness at save time: redraw while taken.
  // This also keeps generated-document folders (keyed by office
  // number) from colliding across applications.
  for (var attempt = 0; attempt < 10; attempt++) {
    if (!await _officeNumberTaken(application.officeNumber)) break;
    application.officeNumber =
        await OfficeNumberService.nextOfficeNumber();
  }

  final row = <String, Object?>{

      // BASIC

      "officeNumber": application.officeNumber,

      "applicationType": application.applicationType,

      "verifiedApplicationType":
          application.verifiedApplicationType,

          "permissionTypeId":
    application.permissionTypeId,

"permissionType":
    application.permissionType,

      "applicantLetterNumber": application.applicantLetterNumber,
      "applicationDate":
          application.applicationDate,

      "receivedDate":
          application.receivedDate,

      "applicantName":
          application.applicantName,

      "applicantAddress":
          application.applicantAddress,

          "treeLocationSame":
    application.treeLocationSame ? 1 : 0,

"treeLocationAddress":
    application.treeLocationAddress,

      "mobile": application.mobile,

      "applicationSource": application.applicationSource,

"forwardedDate": application.forwardedDate,

"drfoAssignmentDate":
    application.drfoAssignmentDate,

// IDs

      "createdBy":
          application.createdBy,

      "sectionId":
          application.sectionId,

      "beatId":
          application.beatId,

      "assignedBFO":
          application.assignedBFOId,

      "assignedDRFO":
          application.assignedDRFOId,

      "sandalDestinationId":
          application.sandalDestinationId,

      "sandalDestinationCustom":
          application.sandalDestinationCustom,

      // PURPOSE

     "purposeId":
    application.purposeId,

"purpose":
    application.purpose,

"whyRemovingId":
    application.whyRemovingId,

      "governmentAgencyId":
    application.governmentAgencyId,

"urbanRuralId":
    application.urbanRuralId,

"structureTypeId":
    application.structureTypeId,

"workName":
    application.workName,

      // BFO

      "gps":
          application.gpsCoordinates,

      "inspectionStarted":
          application.inspectionStarted ? 1 : 0,
          "inspectionDecision":
    application.inspectionDecision,

      "bfoVerificationDate":
          application.bfoVerificationDate,

     "overallRemarkId":
    application.overallRemarkId,

"overallRemarks":
    application.overallRemarks,

      // DRFO

      "drfoInspectionDate":
          application.drfoInspectionDate,

      "drfoOverallRemarks":
          application.drfoOverallRemarks,

      // RFO

      "rfoInspectionStarted":
          application.rfoInspectionStarted ? 1 : 0,

     "rfoInspectionDate":
    application.rfoInspectionDate,

"rfoApprovalDate":
    application.rfoApprovalDate,

"rfoOverallRemarks":
          application.rfoOverallRemarks,

      // RETURN

      "returnReason":
          application.returnReason,

      "returnRemarks":
          application.returnRemarks,

      "returnedBy":
          application.returnedBy,

      "returnedDate":
          application.returnedDate,

     // IMPORTANT

"status": "Draft",

"inspectionMode":
    application.inspectionMode,

"createdDate":
    application.createdDate
        .toIso8601String(),

"updatedAt": DateTime.now().toIso8601String(),

    };

  final int id;

  if (OnlineMode.enabled) {
    id = await OnlineDatabase.insert(
      "applications",
      row,
    );
  } else {
    final db = await _db;

    id = await db.insert(
      "applications",
      row,
    );

    await SyncService.instance.markDirty(
      tableName: 'applications',
      localId: id,
    );
  }

  application.id = id;

  // ======================================================
// SAVE FORWARDING REFERENCES
// ======================================================

final references =
    application.forwardingReferences;

final cloudReferences = <Map<String, Object?>>[];
for (int i = 0; i < references.length; i++) {
  final reference = references[i];

  final refRow = <String, Object?>{
    "applicationId": id,
    "sourceId": reference.sourceId,
    "sourceKind": reference.sourceKind,
    "sourceName": reference.forwardedBy,
    "referenceNumber":
        reference.referenceNumber,
    "referenceDate":
        reference.referenceDate,
    "receivedDate":
        reference.receivedDate,
    "displayOrder": i + 1,
  };

  if (OnlineMode.enabled) {
    cloudReferences.add(refRow);
  } else {
    final db = await _db;

    await db.insert(
      "application_forward_references",
      refRow,
    );
  }
}
if (OnlineMode.enabled) {
  await OnlineDatabase.insertMany("application_forward_references", cloudReferences);
}
return id;

}

  // ======================================
  // UPDATE APPLICATION
  // ======================================

  Future<int> updateApplication(

    ApplicationModel application,

  ) async {

    final row = <String, Object?>{
  "applicationType": application.applicationType,

  "verifiedApplicationType":
      application.verifiedApplicationType,

      "permissionTypeId":
    application.permissionTypeId,

"permissionType":
    application.permissionType,

  "applicantLetterNumber": application.applicantLetterNumber,
      "applicationDate":
      application.applicationDate,

  "receivedDate":
      application.receivedDate,

  "applicantName":
      application.applicantName,

  "applicantAddress":
      application.applicantAddress,

      "treeLocationSame":
    application.treeLocationSame ? 1 : 0,

"treeLocationAddress":
    application.treeLocationAddress,

  "mobile":
      application.mobile,

      "applicationSource": application.applicationSource,

"forwardedDate": application.forwardedDate,

"drfoAssignmentDate":
    application.drfoAssignmentDate,

"sectionId": application.sectionId,

  "beatId":
      application.beatId,

  "purpose":
      application.purpose,

  "governmentAgencyId":
    application.governmentAgencyId,

"urbanRuralId":
    application.urbanRuralId,

"structureTypeId":
    application.structureTypeId,

"workName":
    application.workName,

  "gps":
      application.gpsCoordinates,

  "inspectionStarted":
      application.inspectionStarted ? 1 : 0,
      "inspectionDecision":
    application.inspectionDecision,

 "overallRemarkId":
    application.overallRemarkId,

"overallRemarks":
    application.overallRemarks,

  "bfoVerificationDate":
      application.bfoVerificationDate,

  "drfoInspectionDate":
      application.drfoInspectionDate,

  "drfoOverallRemarks":
      application.drfoOverallRemarks,

  "rfoInspectionStarted":
      application.rfoInspectionStarted ? 1 : 0,

 "rfoInspectionDate":
    application.rfoInspectionDate,

"rfoApprovalDate":
    application.rfoApprovalDate,

"rfoOverallRemarks":
      application.rfoOverallRemarks,

  "returnReason":
      application.returnReason,

  "returnRemarks":
      application.returnRemarks,

  "returnedBy":
      application.returnedBy,

  "returnedDate":
      application.returnedDate,

  "status":
    application.status,

"inspectionMode":
    application.inspectionMode,

"sandalDestinationId":
    application.sandalDestinationId,

"sandalDestinationCustom":
    application.sandalDestinationCustom,

"updatedAt": DateTime.now().toIso8601String(),
};

    if (OnlineMode.enabled) {
      await OnlineDatabase.update(
        "applications",
        application.id!,
        row,
      );
      return 1;
    }

    final db = await _db;

    final rows = await db.update(

      "applications",

      row,

      where: "id=?",

whereArgs: [

  application.id,

],

    );

    if (application.id != null) {
      await SyncService.instance.markDirty(
        tableName: 'applications',
        localId: application.id!,
      );
    }

    return rows;

  }

  // Stage 2 helper: queue sync + stamp workflow transitions.
  Future<void> touchForSync(int applicationId) async {
    if (OnlineMode.enabled) {
      await OnlineDatabase.update(
        'applications',
        applicationId,
        {'updatedAt': DateTime.now().toIso8601String()},
      );
      return;
    }
    final db = await _db;
    await db.update(
      'applications',
      {'updatedAt': DateTime.now().toIso8601String()},
      where: 'id=?',
      whereArgs: [applicationId],
    );
    await SyncService.instance.markDirty(
      tableName: 'applications',
      localId: applicationId,
    );
  }

  // ======================================
// SAVE / REPLACE FORWARDING REFERENCES
// ======================================

Future<void> replaceForwardingReferences(
  int applicationId,
  List<ApplicationReferenceModel> references,
) async {

  if (OnlineMode.enabled) {
    await OnlineDatabase.delete(
      "application_forward_references",
      column: "applicationId",
      value: applicationId,
    );

    for (int i = 0; i < references.length; i++) {
      final reference = references[i];

      await OnlineDatabase.insert(
        "application_forward_references",
        {
          "applicationId": applicationId,
          "sourceId": reference.sourceId,
          "sourceKind": reference.sourceKind,
          "sourceName": reference.forwardedBy,
          "referenceNumber":
              reference.referenceNumber,
          "referenceDate":
              reference.referenceDate,
          "receivedDate":
              reference.receivedDate,
          "displayOrder": i + 1,
        },
      );
    }
    return;
  }

  final db = await _db;

  await db.delete(
    "application_forward_references",
    where: "applicationId=?",
    whereArgs: [applicationId],
  );

  for (int i = 0; i < references.length; i++) {

    final reference = references[i];

    await db.insert(
      "application_forward_references",
      {
        "applicationId": applicationId,
        "sourceId": reference.sourceId,
        "sourceKind": reference.sourceKind,
        "sourceName": reference.forwardedBy,
        "referenceNumber":
            reference.referenceNumber,
        "referenceDate":
            reference.referenceDate,
        "receivedDate":
            reference.receivedDate,
        "displayOrder": i + 1,
      },
    );
  }
}

// ======================================
// GET FORWARDING REFERENCES
// ======================================

  Future<List<ApplicationReferenceModel>> _mapOnlineReferences(
      List<Map<String, dynamic>> rows) async {
    final names = <String, String>{};
    final missingKinds = rows.where((row) => (row['sourceName']?.toString().trim() ?? '').isEmpty)
        .map((row) => row['sourceKind']?.toString() ?? 'SOURCE').toSet();
    await Future.wait([
      if (missingKinds.contains('SOURCE')) () async {
        for (final row in await OnlineDatabase.selectAll('forwarded_source_master')) {
          names['SOURCE_${row['id']}'] = row['sourceName']?.toString() ?? '';
        }
      }(),
      if (missingKinds.contains('AGENCY')) () async {
        for (final row in await OnlineDatabase.selectAll('revenue_opinion_master')) {
          names['AGENCY_${row['id']}'] = [row['officeName'], row['officeAddress']]
              .where((part) => part != null && part.toString().trim().isNotEmpty).join(' - ');
        }
      }(),
      if (missingKinds.contains('OFFICER')) () async {
        for (final row in await OnlineDatabase.selectAll('officer_directory')) {
          names['OFFICER_${row['id']}'] = row['role']?.toString() ?? '';
        }
      }(),
    ]);
    return rows.map((row) {
      final sourceId = (row['sourceId'] as num?)?.toInt() ?? 0;
      final kind =
          row['sourceKind']?.toString() ?? 'SOURCE';
      final savedName =
          row['sourceName']?.toString().trim() ?? '';
      return ApplicationReferenceModel(
        sourceId: sourceId,
        sourceKind: kind,
        forwardedBy: savedName.isNotEmpty
            ? savedName
            : (names['${kind}_$sourceId'] ?? ''),
        referenceNumber:
            row['referenceNumber']?.toString() ?? '',
        referenceDate:
            row['referenceDate']?.toString() ?? '',
        receivedDate:
            row['receivedDate']?.toString() ?? '',
      );
    }).toList();
  }

Future<List<ApplicationReferenceModel>>
    _getForwardingReferences(int applicationId) async {

  if (OnlineMode.enabled) {
    final rows = await OnlineDatabase.select(
      'application_forward_references',
      equals: {'applicationId': applicationId},
      orderBy: 'displayOrder',
    );
    return _mapOnlineReferences(rows);
  }

  final db = await _db;

  final rows = await db.rawQuery(
    '''
    SELECT
  afr.sourceId,
  afr.sourceKind,
  afr.referenceNumber,
  afr.referenceDate,
  afr.receivedDate,
  fsm.sourceName,
  rom.officeName AS agencyOffice,
  rom.revenueOpinion AS agencyName,
  od.name AS officerName,
  od.role AS officerRole
    FROM application_forward_references afr
    LEFT JOIN forwarded_source_master fsm
      ON afr.sourceId = fsm.id AND (afr.sourceKind IS NULL OR afr.sourceKind = 'SOURCE')
    LEFT JOIN revenue_opinion_master rom
      ON afr.sourceId = rom.id AND afr.sourceKind = 'AGENCY'
    LEFT JOIN officer_directory od
      ON afr.sourceId = od.id AND afr.sourceKind = 'OFFICER'
    WHERE afr.applicationId = ?
    ORDER BY afr.displayOrder ASC, afr.id ASC
    ''',
    [applicationId],
  );

  return rows.map((row) {

    final kind =
        row['sourceKind']?.toString() ?? 'SOURCE';

    final savedName =
        row['sourceName']?.toString().trim() ?? '';

    String forwardedBy;
    if (savedName.isNotEmpty) {
      forwardedBy = savedName;
    } else if (kind == 'AGENCY') {
      final office =
          row['agencyOffice']?.toString() ?? '';
      forwardedBy = office.isNotEmpty
          ? "${row['agencyName']} - $office"
          : (row['agencyName']?.toString() ?? '');
    } else if (kind == 'OFFICER') {
      forwardedBy =
          "${row['officerName']} (${row['officerRole']})";
    } else {
      forwardedBy =
          row['sourceName']?.toString() ?? '';
    }

    return ApplicationReferenceModel(
  sourceId:
      (row['sourceId'] as int?) ?? 0,

  sourceKind: kind,

  forwardedBy: forwardedBy,

  referenceNumber:
      row['referenceNumber']?.toString() ?? '',

  referenceDate:
      row['referenceDate']?.toString() ?? '',

  receivedDate:
      row['receivedDate']?.toString() ?? '',
);

  }).toList();
}

  // ======================================
// GET APPLICATION BY ID
// ======================================

Future<ApplicationModel?> getByOfficeNumber(String officeNumber) async {
  if (OnlineMode.enabled) {
    final rows = await OnlineDatabase.select(
      'applications',
      equals: {'officeNumber': officeNumber},
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return await _enrichOnline(rows.first);
  }
  final rows=await (await _db).rawQuery('''SELECT applications.*, section_master.sectionName,
    beat_master.beatName, bfo.name AS assignedBFOName, drfo.name AS assignedDRFOName
    FROM applications LEFT JOIN section_master ON applications.sectionId=section_master.id
    LEFT JOIN beat_master ON applications.beatId=beat_master.id
    LEFT JOIN users bfo ON applications.assignedBFO=bfo.id
    LEFT JOIN users drfo ON applications.assignedDRFO=drfo.id
    WHERE applications.officeNumber=? LIMIT 1''',[officeNumber]);
  if(rows.isEmpty) return null;
  final application=_mapApplication(rows.first);
  application.forwardingReferences=await _getForwardingReferences(application.id!);
  return application;
}

Future<ApplicationModel?> getById(
  int id,
) async {

  if (OnlineMode.enabled) {
    final result = await OnlineDatabase.select(
      'applications',
      equals: {'id': id},
      limit: 1,
    );
    if (result.isEmpty) return null;
    return await _enrichOnline(result.first);
  }

  final db = await _db;

  final result = await db.query(

    "applications",

    where: "id=?",

    whereArgs: [id],

    limit: 1,

  );

  if (result.isEmpty) {

    return null;

  }

  final application = _mapApplication(result.first);

application.forwardingReferences =
    await _getForwardingReferences(id);

return application;

}
    // ======================================
  // ONLINE ENRICHMENT (joins done client-side)
  // ======================================

  Future<ApplicationModel> _enrichOnline(
    Map<String, dynamic> row,
  ) async {
    final enriched = Map<String, dynamic>.from(row);
    final sectionId = (row['sectionId'] as num?)?.toInt();
    final beatId = (row['beatId'] as num?)?.toInt();
    final bfoId = (row['assignedBFO'] as num?)?.toInt();
    final drfoId = (row['assignedDRFO'] as num?)?.toInt();
    List<ApplicationReferenceModel> references = [];
    await Future.wait<void>([
    if (sectionId != null) () async {
      final sections = await OnlineDatabase.select(
        'section_master',
        equals: {'id': sectionId},
        limit: 1,
      );
      if (sections.isNotEmpty) {
        enriched['sectionName'] =
            sections.first['sectionName']?.toString() ?? '';
      }
    }(),
    if (beatId != null) () async {
      final beats = await OnlineDatabase.select(
        'beat_master',
        equals: {'id': beatId},
        limit: 1,
      );
      if (beats.isNotEmpty) {
        enriched['beatName'] =
            beats.first['beatName']?.toString() ?? '';
      }
    }(),
    if (bfoId != null) () async {
      final users = await OnlineDatabase.select(
        'users',
        equals: {'id': bfoId},
        limit: 1,
      );
      if (users.isNotEmpty) {
        enriched['assignedBFOName'] =
            users.first['name']?.toString() ?? '';
      }
    }(),
    if (drfoId != null) () async {
      final users = await OnlineDatabase.select(
        'users',
        equals: {'id': drfoId},
        limit: 1,
      );
      if (users.isNotEmpty) {
        enriched['assignedDRFOName'] =
            users.first['name']?.toString() ?? '';
      }
    }(),
      () async { references = await _getForwardingReferences((row['id'] as num).toInt()); }(),
    ]);
    final application = _mapApplication(enriched);
    application.forwardingReferences = references;
    return application;
  }

    // ======================================
  // APPLICATION MAPPER
  // ======================================

  ApplicationModel _mapApplication(
  Map<String, dynamic> row,
) {

  return ApplicationModel(

    id: row["id"] as int?,

    officeNumber:
        row["officeNumber"]?.toString() ?? "",

    applicationType:
        row["applicationType"]?.toString() ?? "",

    verifiedApplicationType:
        row["verifiedApplicationType"]?.toString() ?? "",

        permissionTypeId:
    row["permissionTypeId"] as int?,

permissionType:
    row["permissionType"]?.toString() ?? "",

    applicantLetterNumber: row['applicantLetterNumber']?.toString() ?? '',
    applicationDate:
        row["applicationDate"]?.toString() ?? "",

    receivedDate:
        row["receivedDate"]?.toString() ?? "",

    applicantName:
        row["applicantName"]?.toString() ?? "",

    applicantAddress:
        row["applicantAddress"]?.toString() ?? "",

        treeLocationSame:
    (row["treeLocationSame"] ?? 1) == 1,

treeLocationAddress:
    row["treeLocationAddress"]?.toString() ?? "",

    mobile:
    row["mobile"]?.toString() ?? "",

applicationSource:
    row["applicationSource"]?.toString() ?? "DIRECT",

forwardedDate:
    row["forwardedDate"]?.toString() ?? "",

drfoAssignmentDate:
    row["drfoAssignmentDate"]?.toString() ?? "",

createdBy:
    row["createdBy"] as int?,

    sectionId:
        row["sectionId"] as int?,

    beatId:
        row["beatId"] as int?,

    assignedBFOId:
        row["assignedBFO"] as int?,

    assignedDRFOId:
        row["assignedDRFO"] as int?,

    sandalDestinationId:
        (row["sandalDestinationId"] as num?)?.toInt(),

    sandalDestinationCustom:
        row["sandalDestinationCustom"]?.toString() ?? "",

    section:
    row["sectionName"]?.toString() ?? "",

beat:
    row["beatName"]?.toString() ?? "",

assignedBFO:
    row["assignedBFOName"]?.toString() ?? "",

assignedDRFO:
    row["assignedDRFOName"]?.toString() ?? "",

    purposeId:
    row["purposeId"] as int?,

purpose:
    row["purpose"]?.toString() ?? "",

whyRemovingId:
    row["whyRemovingId"] as int?,

governmentAgencyId:
    row["governmentAgencyId"] as int?,

urbanRuralId:
    row["urbanRuralId"] as int?,

structureTypeId:
    row["structureTypeId"] as int?,

workName:
    row["workName"]?.toString() ?? "",

    gpsCoordinates:
        row["gps"]?.toString() ?? "",

    bfoVerificationDate:
        row["bfoVerificationDate"]?.toString() ?? "",

    inspectionStarted:
        (row["inspectionStarted"] ?? 0) == 1,
       
        inspectionDecision:
    row["inspectionDecision"]?.toString() ?? "",

deferredReasonIds: [],

    overallRemarkId:
    row["overallRemarkId"] as int?,

overallRemarks:
    row["overallRemarks"]?.toString() ?? "",

    drfoInspectionDate:
        row["drfoInspectionDate"]?.toString() ?? "",

    drfoOverallRemarks:
        row["drfoOverallRemarks"]?.toString() ?? "",

    rfoInspectionStarted:
        (row["rfoInspectionStarted"] ?? 0) == 1,

    rfoInspectionDate:
    row["rfoInspectionDate"]?.toString() ?? "",

rfoApprovalDate:
    row["rfoApprovalDate"]?.toString() ?? "",

rfoOverallRemarks:
        row["rfoOverallRemarks"]?.toString() ?? "",

    returnReason:
        row["returnReason"]?.toString() ?? "",

    returnRemarks:
        row["returnRemarks"]?.toString() ?? "",

    returnedBy:
        row["returnedBy"]?.toString() ?? "",

    returnedDate:
        row["returnedDate"]?.toString() ?? "",

    trees: [],

    status:
        row["status"]?.toString() ?? "",

    inspectionMode:
    row["inspectionMode"]?.toString() ?? "",    

    createdDate:
        DateTime.tryParse(
              row["createdDate"]?.toString() ?? "",
            ) ??
            DateTime.now(),

  );

}

// ======================================
// GET ALL APPLICATIONS
// ======================================

Future<List<ApplicationModel>>
    getApplications({Map<String, Object?>? onlineEquals,
      List<Object>? onlineStatuses}) async {

  if (OnlineMode.enabled) {
    final result = await OnlineDatabase.selectAll('applications',
      equals: onlineEquals, inColumn: onlineStatuses == null ? null : 'status',
      inValues: onlineStatuses, orderBy: 'createdDate', descending: true);
    if (result.isEmpty) return [];
    final lookupData = await Future.wait([
      OnlineDatabase.selectAll('section_master', columns: 'id,sectionName'),
      OnlineDatabase.selectAll('beat_master', columns: 'id,beatName'),
      OnlineDatabase.selectAll('users', columns: 'id,name'),
      () async {
        final rows = <Map<String, dynamic>>[];
        final ids = result.map((row) => row['id'] as Object).toList();
        for (var start = 0; start < ids.length; start += 200) {
          rows.addAll(await OnlineDatabase.selectAll('application_forward_references',
            inColumn: 'applicationId', inValues: ids.skip(start).take(200).toList(),
            orderBy: 'displayOrder'));
        }
        return rows;
      }(),
    ]);
    final sections = lookupData[0], beats = lookupData[1], users = lookupData[2];
    final referenceRows = lookupData[3];
    final mappedReferences = await _mapOnlineReferences(referenceRows);
    final referencesByApplication = <int, List<ApplicationReferenceModel>>{};
    for (var i = 0; i < referenceRows.length; i++) {
      final id = (referenceRows[i]['applicationId'] as num).toInt();
      referencesByApplication.putIfAbsent(id, () => []).add(mappedReferences[i]);
    }
    final sectionNames = <int, String>{
      for (final s in sections)
        (s['id'] as num).toInt(): (s['sectionName']?.toString() ?? ''),
    };
    final beatNames = <int, String>{
      for (final b in beats)
        (b['id'] as num).toInt(): (b['beatName']?.toString() ?? ''),
    };
    final userNames = <int, String>{
      for (final u in users)
        (u['id'] as num).toInt(): (u['name']?.toString() ?? ''),
    };
    final applications = <ApplicationModel>[];
    for (final row in result) {
      final enriched = Map<String, dynamic>.from(row);
      final sectionId = (row['sectionId'] as num?)?.toInt();
      final beatId = (row['beatId'] as num?)?.toInt();
      final bfoId = (row['assignedBFO'] as num?)?.toInt();
      final drfoId = (row['assignedDRFO'] as num?)?.toInt();
      enriched['sectionName'] =
          sectionId == null ? '' : (sectionNames[sectionId] ?? '');
      enriched['beatName'] =
          beatId == null ? '' : (beatNames[beatId] ?? '');
      enriched['assignedBFOName'] =
          bfoId == null ? '' : (userNames[bfoId] ?? '');
      enriched['assignedDRFOName'] =
          drfoId == null ? '' : (userNames[drfoId] ?? '');
      final application = _mapApplication(enriched);
      if (application.id != null) {
        application.forwardingReferences =
            referencesByApplication[application.id!] ?? [];
      }
      applications.add(application);
    }
    return applications;
  }

  final db = await _db;

  final result = await db.rawQuery("""

SELECT

applications.*,

section_master.sectionName,

beat_master.beatName,

bfo.name AS assignedBFOName,

drfo.name AS assignedDRFOName

FROM applications

LEFT JOIN section_master

ON applications.sectionId = section_master.id

LEFT JOIN beat_master

ON applications.beatId = beat_master.id

LEFT JOIN users bfo

ON applications.assignedBFO = bfo.id

LEFT JOIN users drfo

ON applications.assignedDRFO = drfo.id

ORDER BY applications.createdDate DESC

""");

 final applications = result
    .map(_mapApplication)
    .toList();

for (final application in applications) {
  if (application.id != null) {
    application.forwardingReferences =
        await _getForwardingReferences(application.id!);
  }
}

return applications;

}
// ======================================
// CASE WORKER APPLICATIONS
// ======================================

Future<List<ApplicationModel>>
    getApplicationsForCaseWorker(
        int userId) async {

  final all = await getApplications(onlineEquals: {'createdBy': userId}, onlineStatuses: ['Draft', 'Pending DRFO Assignment', 'Returned to Case Worker']);

  return all.where((app) {

    return app.createdBy == userId &&
        (app.status == "Draft" ||
         app.status == "Pending DRFO Assignment" ||
         app.status == "Returned to Case Worker");

  }).toList();

}

Future<List<ApplicationModel>>
    searchApplications(
      {String? officeNumber,
      String? applicantName,
      String? applicationType,
      int? sectionId,
      int? beatId,
    }) async {
  final all = await getApplications();

  return all.where((app) {
    bool match = true;

    if (officeNumber != null &&
        (app.officeNumber ?? '').trim().toUpperCase()
            .contains(officeNumber.trim().toUpperCase())) {
      match = false;
    }
    if (applicantName != null &&
        (app.applicantName ?? '').trim().toUpperCase()
            .contains(applicantName.trim().toUpperCase())) {
      match = false;
    }
    if (applicationType != null &&
        (app.applicationType ?? '').trim().toUpperCase()
            .contains(applicationType.trim().toUpperCase())) {
      match = false;
    }
    if (sectionId != null && (app.sectionId ?? -1) != sectionId) {
      match = false;
    }
    if (beatId != null && (app.beatId ?? -1) != beatId) {
      match = false;
    }

    return match;
  }).toList();
}

Future<List<ApplicationModel>>
    getRfoApprovedApplicationsForCaseWorker(
  int userId,
) async {
  final all = await getApplications(onlineEquals: {'createdBy': userId}, onlineStatuses: [WorkflowStatus.pendingRevenueOpinion, WorkflowStatus.approved]);

  final candidates = all.where((application) {
   return application.createdBy == userId &&
    (application.status ==
            WorkflowStatus.pendingRevenueOpinion ||
        application.status ==
            WorkflowStatus.approved);
  }).toList();
  final result = <ApplicationModel>[];
  for (final application in candidates) {
    final cycle = await RevenueReplyRepository().current(application.id!);
    if (application.status != WorkflowStatus.pendingRevenueOpinion || cycle == null || cycle.stage == 'printing') result.add(application);
  }
  // Exclude completed applications — they move to the new "Completed Applications" tab.
  return result.where((app) => app.status != WorkflowStatus.completed).toList();
}

// ======================================
// DRFO APPLICATIONS
// ======================================

Future<List<ApplicationModel>>
    getApplicationsForDRFO(
        int sectionId) async {

  final all = await getApplications(onlineEquals: {'sectionId': sectionId});

  return all.where((app) {

    return app.sectionId == sectionId && (

      app.status == WorkflowStatus.pendingDRFOAssignment ||

      app.status == WorkflowStatus.pendingBFOInspection ||

      app.status == WorkflowStatus.pendingDRFOVerification ||

      app.status == WorkflowStatus.pendingDRFOSelfInspection ||

      app.status == WorkflowStatus.pendingDRFOReSelfInspection ||

      app.status == WorkflowStatus.returnedToBFO

      || app.status == WorkflowStatus.pendingRFOApproval

    );

  }).toList();

}

// ======================================
// BFO APPLICATIONS
// ======================================

Future<List<ApplicationModel>>
    getApplicationsForBFO(
        int userId) async {

  final all = await getApplications(onlineEquals: {'assignedBFO': userId}, onlineStatuses: [WorkflowStatus.pendingBFOInspection, WorkflowStatus.returnedToBFO]);

  return all.where((app) {

    return app.assignedBFOId == userId && (

    app.status ==
        WorkflowStatus.pendingBFOInspection ||

    app.status ==
        WorkflowStatus.returnedToBFO

);

  }).toList();

}

Future<List<ApplicationModel>>
    getCompletedInspectionsForBFO(
  int userId,
) async {
  final all = await getApplications(onlineEquals: {'assignedBFO': userId});

  const completedStatuses = {
  WorkflowStatus.pendingDRFOVerification,
  WorkflowStatus.pendingRFOApproval,
  WorkflowStatus.completed,
  WorkflowStatus.approved,
  WorkflowStatus.rejected,
  WorkflowStatus.returnedToDRFO,
  WorkflowStatus.returnedToCaseWorker,
};

  return all.where((application) {
    return application.assignedBFOId == userId &&
        application.inspectionStarted &&
        completedStatuses.contains(
          application.status,
        );
  }).toList();
}

// ======================================
// RFO APPLICATIONS
// ======================================

Future<List<ApplicationModel>>
    getApplicationsForRFO() async {

  final all = await getApplications(onlineStatuses: [WorkflowStatus.pendingRFOApproval, WorkflowStatus.completed]);

  return all.where((app) {

    return app.status ==
        WorkflowStatus.pendingRFOApproval ||
        app.status == WorkflowStatus.completed;

  }).toList();

}
  // ======================================
  // SUBMIT TO DRFO
  // ======================================

  Future<void> submitToDRFO(
  ApplicationModel application,
) async {

  if (application.sectionId == null) throw StateError('Select a section before forwarding.');
  final drfo = await UserRepository().getDRFOBySection(application.sectionId!);
  if (drfo == null) throw StateError('No active DRFO is mapped to this section. Configure User Master first.');
  application.assignedDRFOId = (drfo['id'] as num).toInt();
  final now = DateTime.now();

  application.drfoAssignmentDate =
      "${now.day.toString().padLeft(2, '0')}/"
      "${now.month.toString().padLeft(2, '0')}/"
      "${now.year}";

  application.status =
      "Pending DRFO Assignment";

  await updateApplication(
    application,
  );
}

  // ======================================
  // RETURN TO BFO
  // ======================================

  Future<void> returnToBFO(

    ApplicationModel application,

  ) async {

    application.status = "Pending BFO Inspection";

    await updateApplication(

      application,

    );

  }
    // ======================================
  // DASHBOARD COUNTS
  // ======================================

  Future<Map<String, int>>
      getDashboardCounts() async {

  if (OnlineMode.enabled) {
    final rows = await OnlineDatabase.select('applications');
    int count(String status) =>
        rows.where((r) => (r['status']?.toString() ?? '') == status).length;
    return {
      "Total": rows.length,
      "Draft": count("Draft"),
      "Pending DRFO Assignment": count("Pending DRFO Assignment"),
      "Pending BFO Inspection": count("Pending BFO Inspection"),
      "Pending DRFO Verification":
          count("Pending DRFO Verification"),
      "Pending RFO Approval":
          count(WorkflowStatus.pendingRFOApproval),
      "Completed": count(WorkflowStatus.completed),
      "Approved": count(WorkflowStatus.approved),
      "Rejected": count("Rejected"),
    };
  }

    final db = await _db;

    Future<int> count(

      String status,

    ) async {

      final result = await db.rawQuery(

        "SELECT COUNT(*) as cnt FROM applications WHERE status=?",

        [

          status,

        ],

      );

      return Sqflite.firstIntValue(

            result,

          ) ??
          0;

    }

    final total = Sqflite.firstIntValue(

          await db.rawQuery(

            "SELECT COUNT(*) FROM applications",

          ),

        ) ??
        0;

    return {

  "Total": total,

  "Draft":
      await count("Draft"),

  "Pending DRFO Assignment":
      await count("Pending DRFO Assignment"),

  "Pending BFO Inspection":
      await count("Pending BFO Inspection"),

  "Pending DRFO Verification":
      await count("Pending DRFO Verification"),

  "Pending RFO Approval":
    await count(
      WorkflowStatus.pendingRFOApproval,
    ),

  "Completed":
    await count(
      WorkflowStatus.completed,
    ),

"Approved":
    await count(
      WorkflowStatus.approved,
    ),

  "Rejected":
      await count("Rejected"),

};

  }

  // ======================================
  // UPDATE WORKFLOW
  // ======================================

  Future<void> updateWorkflow({

    required int applicationId,

    required String status,

    required String inspectionMode,

    required int assignedBFO,

  }) async {

    if (OnlineMode.enabled) {
      await OnlineDatabase.update(
        "applications",
        applicationId,
        {
          "status": status,
          "inspectionMode": inspectionMode,
          "assignedBFO": assignedBFO,
        },
      );
      return;
    }

    final db = await _db;

    await db.update(

      "applications",

      {

        "status": status,

        "inspectionMode":
            inspectionMode,

        "assignedBFO":
            assignedBFO,

      },

      where: "id=?",

      whereArgs: [

        applicationId,

      ],

    );

  }
  Future<int> getLastTreeNumber(
  int applicationId,
) async {
  if (OnlineMode.enabled) {
    final result = await OnlineDatabase.select(
      'applications',
      equals: {'id': applicationId},
      limit: 1,
    );
    if (result.isEmpty) return 0;
    return (result.first['lastTreeNumber'] as num?)?.toInt() ?? 0;
  }
  final db = await _db;

  final result = await db.query(
    'applications',
    columns: ['lastTreeNumber'],
    where: 'id=?',
    whereArgs: [applicationId],
    limit: 1,
  );

  if (result.isEmpty) return 0;

  return (result.first['lastTreeNumber'] as int?) ?? 0;
}

Future<void> updateLastTreeNumber(
    int applicationId,
    int number,
) async {

  if (OnlineMode.enabled) {
    await OnlineDatabase.update(
      'applications',
      applicationId,
      {'lastTreeNumber': number},
    );
    return;
  }

  final db = await _db;

  await db.update(
    'applications',
    {
      'lastTreeNumber': number,
    },
    where: 'id=?',
    whereArgs: [applicationId],
  );
}
  }