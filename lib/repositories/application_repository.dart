import 'revenue_reply_repository.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../models/application_model.dart';
import '../models/application_reference_model.dart';
import '../constants/workflow_status.dart';
import '../services/online_database.dart';
import '../services/online_mode.dart';
import '../services/sync_service.dart';

class ApplicationRepository {
  final DatabaseHelper dbHelper =
      DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  // ======================================
  // INSERT APPLICATION
  // ======================================

  Future<int> insertApplication(
    ApplicationModel application) async {

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
    await OnlineDatabase.insert(
      "application_forward_references",
      refRow,
    );
  } else {
    final db = await _db;

    await db.insert(
      "application_forward_references",
      refRow,
    );
  }
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

Future<List<ApplicationReferenceModel>>
    _getForwardingReferences(int applicationId) async {

  if (OnlineMode.enabled) {
    final rows = await OnlineDatabase.select(
      'application_forward_references',
      equals: {'applicationId': applicationId},
      orderBy: 'displayOrder',
    );
    final sources = await OnlineDatabase.select(
      'forwarded_source_master',
    );
    final names = <String, String>{};
    for (final s in sources) {
      names['SOURCE_${(s['id'] as num).toInt()}'] =
          (s['sourceName']?.toString() ?? '');
    }
    final agencies = await OnlineDatabase.select(
      'revenue_opinion_master',
    );
    for (final a in agencies) {
      names['AGENCY_${(a['id'] as num).toInt()}'] =
          (a['officeName']?.toString() ?? '').isNotEmpty
              ? "${a['revenueOpinion']} - ${a['officeName']}"
              : (a['revenueOpinion']?.toString() ?? '');
    }
    final officers = await OnlineDatabase.select(
      'officer_directory',
    );
    for (final o in officers) {
      names['OFFICER_${(o['id'] as num).toInt()}'] =
          "${o['name']} (${o['role']})";
    }
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
    if (sectionId != null) {
      final sections = await OnlineDatabase.select(
        'section_master',
        equals: {'id': sectionId},
        limit: 1,
      );
      if (sections.isNotEmpty) {
        enriched['sectionName'] =
            sections.first['sectionName']?.toString() ?? '';
      }
    }
    if (beatId != null) {
      final beats = await OnlineDatabase.select(
        'beat_master',
        equals: {'id': beatId},
        limit: 1,
      );
      if (beats.isNotEmpty) {
        enriched['beatName'] =
            beats.first['beatName']?.toString() ?? '';
      }
    }
    if (bfoId != null) {
      final users = await OnlineDatabase.select(
        'users',
        equals: {'id': bfoId},
        limit: 1,
      );
      if (users.isNotEmpty) {
        enriched['assignedBFOName'] =
            users.first['name']?.toString() ?? '';
      }
    }
    if (drfoId != null) {
      final users = await OnlineDatabase.select(
        'users',
        equals: {'id': drfoId},
        limit: 1,
      );
      if (users.isNotEmpty) {
        enriched['assignedDRFOName'] =
            users.first['name']?.toString() ?? '';
      }
    }
    final application = _mapApplication(enriched);
    if (application.id != null) {
      application.forwardingReferences =
          await _getForwardingReferences(application.id!);
    }
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
    getApplications() async {

  if (OnlineMode.enabled) {
    final result = await OnlineDatabase.select(
      'applications',
      orderBy: 'createdDate',
      descending: true,
    );
    final sections = await OnlineDatabase.select('section_master');
    final beats = await OnlineDatabase.select('beat_master');
    final users = await OnlineDatabase.select('users');
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
            await _getForwardingReferences(application.id!);
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

  final all = await getApplications();

  return all.where((app) {

    return app.createdBy == userId &&
        (app.status == "Draft" ||
         app.status == "Pending DRFO Assignment" ||
         app.status == "Returned to Case Worker");

  }).toList();

}

Future<List<ApplicationModel>>
    getRfoApprovedApplicationsForCaseWorker(
  int userId,
) async {
  final all = await getApplications();

  final candidates = all.where((application) {
   return application.createdBy == userId &&
    (application.status ==
            WorkflowStatus.pendingRevenueOpinion ||
        application.status ==
            WorkflowStatus.completed ||
        application.status ==
            WorkflowStatus.approved);
  }).toList();
  final result = <ApplicationModel>[];
  for (final application in candidates) {
    final cycle = await RevenueReplyRepository().current(application.id!);
    if (application.status != WorkflowStatus.pendingRevenueOpinion || cycle == null || cycle.stage == 'printing') result.add(application);
  }
  return result;
}

// ======================================
// DRFO APPLICATIONS
// ======================================

Future<List<ApplicationModel>>
    getApplicationsForDRFO(
        int sectionId) async {

  final all = await getApplications();

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

  final all = await getApplications();

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
  final all = await getApplications();

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

  final all = await getApplications();

  return all.where((app) {

    return app.status ==
        WorkflowStatus.pendingRFOApproval;

  }).toList();

}
  // ======================================
  // SUBMIT TO DRFO
  // ======================================

  Future<void> submitToDRFO(
  ApplicationModel application,
) async {

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