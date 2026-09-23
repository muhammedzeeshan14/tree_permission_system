import '../repositories/revenue_reply_repository.dart';
import '../repositories/tree_officer_repository.dart';
import '../repositories/officer_repository.dart';
import '../repositories/government_approval_repository.dart';
import '../constants/master_kannada.dart';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:flutter/foundation.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB();

    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();

debugPrint("DB PATH: $dbPath");

final path = join(dbPath, "tpms.db");

debugPrint("DB FILE: $path");

print("DATABASE PATH = $path");

    return await openDatabase(
      path,
    version: 46,

      onCreate: _createDB,
 onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
CREATE TABLE users(

id INTEGER PRIMARY KEY AUTOINCREMENT,

name TEXT,

username TEXT,

password TEXT,

role TEXT,

sectionId INTEGER,

beatId INTEGER,

isActive INTEGER

)
''');

    await db.execute('''
CREATE TABLE applications(

id INTEGER PRIMARY KEY AUTOINCREMENT,

officeNumber TEXT,

applicationType TEXT,

verifiedApplicationType TEXT,

permissionTypeId INTEGER,

permissionType TEXT,

applicantLetterNumber TEXT NOT NULL DEFAULT '',
applicationDate TEXT,

receivedDate TEXT,

applicantName TEXT,

applicantAddress TEXT,

treeLocationSame INTEGER DEFAULT 1,

treeLocationAddress TEXT,

mobile TEXT,

applicationSource TEXT,

forwardedDate TEXT,
drfoAssignmentDate TEXT,

sectionId INTEGER,

beatId INTEGER,

purposeId INTEGER,

purpose TEXT,

whyRemovingId INTEGER,
governmentAgencyId INTEGER,

urbanRuralId INTEGER,

structureTypeId INTEGER,

workName TEXT,

gps TEXT,

inspectionStarted INTEGER,
inspectionDecision TEXT,

overallRemarkId INTEGER,
overallRemarks TEXT,

bfoVerificationDate TEXT,

drfoInspectionDate TEXT,

drfoOverallRemarks TEXT,

rfoInspectionStarted INTEGER,

rfoInspectionDate TEXT,

rfoOverallRemarks TEXT,

returnReason TEXT,

returnRemarks TEXT,

returnedBy TEXT,

returnedDate TEXT,

status TEXT,

inspectionMode TEXT,

treeCountSiteDetails TEXT,

createdDate TEXT,

rfoApprovalDate TEXT,

createdBy INTEGER,

assignedBFO INTEGER,

assignedDRFO INTEGER,

lastTreeNumber INTEGER DEFAULT 0

)
''');

    await db.execute('''
CREATE TABLE trees(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationId INTEGER,

treeNumber TEXT,

baseTreeNumber INTEGER,

stemType TEXT,

stemLetter TEXT,

stemSequence INTEGER,

isLastStem INTEGER DEFAULT 1,

speciesId INTEGER,

recommendationTypeId INTEGER,

treeStatusId INTEGER,

gbh REAL,

height REAL,

notFitForTimber INTEGER DEFAULT 0,

numberOfBranches INTEGER,

numberOfTwigs INTEGER,

firewood REAL,

recommendationReasonIds TEXT,

remarks TEXT

)
''');



    await db.execute('''
CREATE TABLE section_master(

id INTEGER PRIMARY KEY AUTOINCREMENT,

sectionName TEXT,

kannadaName TEXT,

displayOrder INTEGER,

isActive INTEGER

)
''');

    await db.execute('''
CREATE TABLE beat_master(

id INTEGER PRIMARY KEY AUTOINCREMENT,

sectionId INTEGER,

beatName TEXT,

kannadaName TEXT,

displayOrder INTEGER,

isActive INTEGER

)
''');

   await db.execute('''
CREATE TABLE master_data(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  masterType TEXT,
  value TEXT,
  code TEXT,
  parentCode TEXT,
  displayOrder INTEGER,
  remarks TEXT,
  isActive INTEGER,

  speciesGroup TEXT,
  scientificName TEXT,
  kannadaName TEXT,

  ratePerCubicMeter REAL,

  lengthFrom REAL,
  lengthUpto REAL,
  girthFrom REAL,
  girthUpto REAL,

  ratePerPole REAL,

  category TEXT,

  ratePerTon REAL
)
''');

    await db.execute('''
CREATE TABLE pole_rate_master(

id INTEGER PRIMARY KEY AUTOINCREMENT,

speciesId INTEGER NOT NULL,

lengthFrom REAL,

lengthUpto REAL,

girthFrom REAL,

girthUpto REAL,

rate REAL,

category TEXT,

displayOrder INTEGER,

isActive INTEGER

)
''');

await db.execute('''
CREATE TABLE application_history(

id INTEGER PRIMARY KEY AUTOINCREMENT,

officeNumber TEXT,

action TEXT,

remarks TEXT,

actionBy TEXT,

actionDate TEXT

)
''');
await db.execute('''

CREATE TABLE office_configuration(

id INTEGER PRIMARY KEY AUTOINCREMENT,

rangeName TEXT,

rangeLocation TEXT,

rangeCode TEXT,

officePrefix TEXT,

financialYear TEXT,

rangeOfficeAddress TEXT,

rangeEmail TEXT,

rfoOfficeLogoPath TEXT,

division TEXT,

subDivision TEXT

)

''');

await db.execute('''
CREATE TABLE rfo_letter_configuration(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  applicationTypeCode TEXT NOT NULL UNIQUE,
  letterNumber TEXT
)
''');

await db.execute('''

CREATE TABLE application_type_master(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationType TEXT,

kannadaName TEXT,

shortCode TEXT,

displayOrder INTEGER,

isActive INTEGER

)

''');

await db.execute('''

CREATE TABLE permission_type_master(

id INTEGER PRIMARY KEY AUTOINCREMENT,

permissionType TEXT,

displayOrder INTEGER,

isActive INTEGER

)

''');

await db.execute('''

CREATE TABLE application_type_permission_mapping(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationTypeId INTEGER,

permissionTypeId INTEGER

)

''');

await db.execute("""

CREATE TABLE application_tree_count_site(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationId INTEGER NOT NULL,

siteDetails TEXT,

displayOrder INTEGER NOT NULL

)

""");

await db.execute("""

CREATE TABLE application_tree_count(

id INTEGER PRIMARY KEY AUTOINCREMENT,

siteId INTEGER NOT NULL,

speciesId INTEGER NOT NULL,

treeCount INTEGER NOT NULL,

displayOrder INTEGER NOT NULL

)

""");

await db.execute("""

CREATE TABLE application_mahazar(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationId INTEGER NOT NULL,

mahazarDate TEXT,

startTime TEXT,

startTimeManual TEXT,

endTime TEXT,

endTimeManual TEXT,
northLocationId INTEGER,

eastLocationId INTEGER,

southLocationId INTEGER,

westLocationId INTEGER,

northBoundary TEXT,

eastBoundary TEXT,

southBoundary TEXT,

westBoundary TEXT

)

""");

await db.execute("""

CREATE TABLE revenue_opinion_master(

id INTEGER PRIMARY KEY AUTOINCREMENT,

revenueOpinion TEXT,

code TEXT,

officeName TEXT,

officeAddress TEXT,

kannadaName TEXT,

kannadaDesignation TEXT,

kannadaOfficeAddress TEXT,

remarks TEXT,

displayOrder INTEGER,

isActive INTEGER

)

""");

await db.execute("""

CREATE TABLE forwarded_source_master(

id INTEGER PRIMARY KEY AUTOINCREMENT,

sourceName TEXT,

shortCode TEXT,

displayOrder INTEGER,

isActive INTEGER

)

""");

await db.execute("""

CREATE TABLE inspection_photos(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationId INTEGER,

treeId INTEGER,

photoPath TEXT,

caption TEXT,

createdDate TEXT

)

""");
await db.execute("""

CREATE TABLE inspection_documents(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationId INTEGER,

documentName TEXT,

filePath TEXT,

remarks TEXT,

createdDate TEXT

)

""");

await db.execute("""

CREATE TABLE inspection_defer_reason_master(

id INTEGER PRIMARY KEY AUTOINCREMENT,

reason TEXT,

displayOrder INTEGER,

isActive INTEGER

)

""");

await db.execute("""

CREATE TABLE inspection_deferred_reasons(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationId INTEGER,

reasonId INTEGER,

reasonName TEXT,

displayOrder INTEGER

)

""");

await db.execute("""

CREATE TABLE application_verifications(

applicationId INTEGER PRIMARY KEY,

applicationTypeCorrect INTEGER,

governmentAgencyCorrect INTEGER,

urbanRuralCorrect INTEGER,

structureTypeCorrect INTEGER,

workNameCorrect INTEGER,

overallRemarkCorrect INTEGER,

gpsCorrect INTEGER,

photosCorrect INTEGER,

documentsCorrect INTEGER,

applicationTypeReason TEXT,

governmentAgencyReason TEXT,

urbanRuralReason TEXT,

structureTypeReason TEXT,

workNameReason TEXT,

overallRemarkReason TEXT,

gpsReason TEXT,

photosReason TEXT,

documentsReason TEXT,

whyRemovingCorrect INTEGER,

purposeCorrect INTEGER,

whyRemovingReason TEXT,

purposeReason TEXT,

applicationTypeStatus TEXT,

governmentAgencyStatus TEXT,

urbanRuralStatus TEXT,

whyRemovingStatus TEXT,

purposeStatus TEXT,

structureTypeStatus TEXT,

workNameStatus TEXT,

overallRemarkStatus TEXT,

gpsStatus TEXT,

photosStatus TEXT,

documentsStatus TEXT,

deferredCorrect INTEGER,

deferredReason TEXT,

verifiedBy TEXT,

verifiedDate TEXT

)

""");

await db.execute("""

CREATE TABLE application_forward_references(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationId INTEGER,

sourceId INTEGER,

sourceKind TEXT NOT NULL DEFAULT 'SOURCE',

sourceName TEXT NOT NULL DEFAULT '',

referenceNumber TEXT,

referenceDate TEXT,

receivedDate TEXT,

displayOrder INTEGER

)

""");

await db.execute("""

CREATE TABLE tree_verifications(

treeId INTEGER PRIMARY KEY,
verification TEXT,
verificationReason TEXT,
verifiedBy TEXT,
verifiedDate TEXT

)

""");

await db.execute("""
CREATE TABLE rfo_item_approvals(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  applicationId INTEGER NOT NULL,
  itemKey TEXT NOT NULL,
  itemId INTEGER NOT NULL DEFAULT 0,
  decision TEXT,
  reason TEXT,
  approvedBy TEXT,
  approvedDate TEXT,
  UNIQUE(applicationId, itemKey, itemId)
)
""");

await db.execute("""
CREATE TABLE rfo_deferred_letter_recipients(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  applicationId INTEGER NOT NULL,
  recipientKey TEXT NOT NULL,
  sourceId INTEGER,
  sourceKind TEXT NOT NULL DEFAULT 'SOURCE',
  recipientText TEXT NOT NULL,
  isPrimary INTEGER NOT NULL DEFAULT 0,
  displayOrder INTEGER NOT NULL DEFAULT 0,
  UNIQUE(
    applicationId,
    recipientKey
  )
)
""");

await db.execute("""

CREATE TABLE application_revenue_opinion(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationId INTEGER,

revenueOpinionId INTEGER

)

""");

await _createTreeCountVerificationTable(db);
await _createRevenueOpinionVerificationTable(db);
await _createMahazarVerificationTable(db);
await RevenueReplyRepository.createTable(db);
await TreeOfficerRepository.createTables(db);
await OfficerRepository.createTable(db);
await GovernmentApprovalRepository.createTable(db);
await _createSyncQueueTable(db);
await _ensureFreshSyncColumns(db);
await _createOfficeCounterTable(db);
await seedDevelopmentData(db);
  }

Future<void> _onUpgrade(
  Database db,
  int oldVersion,
  int newVersion,
) async {
  if (oldVersion < 35) await RevenueReplyRepository.createTable(db);
  if (oldVersion < 36) await TreeOfficerRepository.createTables(db);
  if (oldVersion < 37) await OfficerRepository.createTable(db);
  if (oldVersion < 38) await GovernmentApprovalRepository.createTable(db);
  if (oldVersion < 39) await db.execute("ALTER TABLE applications ADD COLUMN applicantLetterNumber TEXT NOT NULL DEFAULT ''");

  // ============================================================
  // VERSION 5
  // ============================================================

  if (oldVersion < 5) {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS application_tree_count_site(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        applicationId INTEGER NOT NULL,
        siteDetails TEXT,
        displayOrder INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS application_tree_count(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        siteId INTEGER NOT NULL,
        speciesId INTEGER NOT NULL,
        treeCount INTEGER NOT NULL,
        displayOrder INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS application_mahazar(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        applicationId INTEGER NOT NULL,
        mahazarDate TEXT,
        startTime TEXT,
        startTimeManual TEXT,
        endTime TEXT,
        endTimeManual TEXT,
        northLocationId INTEGER,
eastLocationId INTEGER,
southLocationId INTEGER,
westLocationId INTEGER,
        northBoundary TEXT,
        eastBoundary TEXT,
        southBoundary TEXT,
        westBoundary TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS forwarded_source_master(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sourceName TEXT,
        shortCode TEXT,
        displayOrder INTEGER,
        isActive INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS application_forward_references(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        applicationId INTEGER,
        sourceId INTEGER,
        referenceNumber TEXT,
        referenceDate TEXT,
        displayOrder INTEGER
      )
    ''');

    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        "SELECT COUNT(*) FROM forwarded_source_master",
      ),
    ) ?? 0;

    if (count == 0) {
      final sources = [
        {
          "sourceName": "DCF Office",
          "shortCode": "DCF",
          "displayOrder": 1,
          "isActive": 1,
        },
        {
          "sourceName": "ACF Office",
          "shortCode": "ACF",
          "displayOrder": 2,
          "isActive": 1,
        },
        {
          "sourceName": "MCC",
          "shortCode": "MCC",
          "displayOrder": 3,
          "isActive": 1,
        },
        {
          "sourceName": "MUDA",
          "shortCode": "MUDA",
          "displayOrder": 4,
          "isActive": 1,
        },
        {
          "sourceName": "NHAI",
          "shortCode": "NHAI",
          "displayOrder": 5,
          "isActive": 1,
        },
        {
          "sourceName": "BESCOM",
          "shortCode": "BESCOM",
          "displayOrder": 6,
          "isActive": 1,
        },
        {
          "sourceName": "KPTCL",
          "shortCode": "KPTCL",
          "displayOrder": 7,
          "isActive": 1,
        },
        {
          "sourceName": "PWD",
          "shortCode": "PWD",
          "displayOrder": 8,
          "isActive": 1,
        },
        {
          "sourceName": "Gram Panchayat",
          "shortCode": "GP",
          "displayOrder": 9,
          "isActive": 1,
        },
        {
          "sourceName": "Taluk Office",
          "shortCode": "TALUK",
          "displayOrder": 10,
          "isActive": 1,
        },
        {
          "sourceName": "Deputy Commissioner's Office",
          "shortCode": "DC",
          "displayOrder": 11,
          "isActive": 1,
        },
        {
          "sourceName": "Others",
          "shortCode": "OTHER",
          "displayOrder": 12,
          "isActive": 1,
        },
      ];

      for (final source in sources) {
        await db.insert(
          "forwarded_source_master",
          source,
        );
      }
    }
  }

  // ============================================================
  // VERSION 7
  // ============================================================

  if (oldVersion < 7) {
    await db.execute(
      "ALTER TABLE trees ADD COLUMN notFitForTimber INTEGER DEFAULT 0",
    );
  }

  // ============================================================
  // VERSION 8
  // ============================================================

  if (oldVersion < 8) {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS revenue_opinion_master(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        revenueOpinion TEXT,
        code TEXT,
        officeName TEXT,
        officeAddress TEXT,
        remarks TEXT,
        displayOrder INTEGER,
        isActive INTEGER
      )
    ''');
  }

  // ============================================================
  // VERSION 9
  // ============================================================

  if (oldVersion < 9) {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS application_revenue_opinion(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        applicationId INTEGER,
        revenueOpinionId INTEGER
      )
    ''');
  }

  // ============================================================
  // VERSION 10
  // ============================================================

  if (oldVersion < 10) {
    await _createTreeCountVerificationTable(db);
  }

  // ============================================================
  // VERSION 11
  // ============================================================

  if (oldVersion < 11) {
    await _createRevenueOpinionVerificationTable(db);
  }

  // ============================================================
  // VERSION 12
  // ============================================================

  if (oldVersion < 12) {
    await _createMahazarVerificationTable(db);
  }

  // ============================================================
  // VERSION 13+
  // SAFELY ENSURE ALL SPECIES COLUMNS EXIST
  // ============================================================

  final columns = await db.rawQuery(
    "PRAGMA table_info(master_data)",
  );

  final existingColumns = columns
      .map((column) => column["name"] as String)
      .toSet();

  Future<void> addColumnIfMissing(
    String columnName,
    String columnDefinition,
  ) async {
    if (!existingColumns.contains(columnName)) {
      await db.execute(
        "ALTER TABLE master_data "
        "ADD COLUMN $columnName $columnDefinition",
      );

      existingColumns.add(columnName);
    }
  }

  await addColumnIfMissing(
    "speciesGroup",
    "TEXT",
  );

  await addColumnIfMissing(
    "scientificName",
    "TEXT",
  );

  await addColumnIfMissing(
    "kannadaName",
    "TEXT",
  );

  await addColumnIfMissing(
    "ratePerCubicMeter",
    "REAL",
  );

  await addColumnIfMissing(
    "lengthFrom",
    "REAL",
  );

  await addColumnIfMissing(
    "lengthUpto",
    "REAL",
  );

  await addColumnIfMissing(
    "girthFrom",
    "REAL",
  );

  await addColumnIfMissing(
    "girthUpto",
    "REAL",
  );

  await addColumnIfMissing(
    "ratePerPole",
    "REAL",
  );

  await addColumnIfMissing(
    "category",
    "TEXT",
  );

  await addColumnIfMissing(
    "ratePerTon",
    "REAL",
  );

  // ============================================================
  // POLE RATE MASTER
  // ============================================================

  await db.execute('''
    CREATE TABLE IF NOT EXISTS pole_rate_master(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      speciesId INTEGER NOT NULL,
      lengthFrom REAL,
      lengthUpto REAL,
      girthFrom REAL,
      girthUpto REAL,
      rate REAL,
      category TEXT,
      displayOrder INTEGER,
      isActive INTEGER
    )
  ''');

  // ============================================================
  // VERSION 20
  // FINAL DATABASE REPAIR
  // ============================================================

  if (oldVersion < 20) {

    // Make sure all species columns exist even if
    // the user's existing database was created by
    // an older/incomplete version.

    final verifyColumns = await db.rawQuery(
      "PRAGMA table_info(master_data)",
    );

    final verifySet = verifyColumns
        .map((column) => column["name"] as String)
        .toSet();

    Future<void> repairColumn(
      String name,
      String definition,
    ) async {
      if (!verifySet.contains(name)) {
        await db.execute(
          "ALTER TABLE master_data "
          "ADD COLUMN $name $definition",
        );
        verifySet.add(name);
      }
    }

    await repairColumn(
      "speciesGroup",
      "TEXT",
    );

    await repairColumn(
      "scientificName",
      "TEXT",
    );

    await repairColumn(
      "kannadaName",
      "TEXT",
    );

    await repairColumn(
      "ratePerCubicMeter",
      "REAL",
    );

    await repairColumn(
      "lengthFrom",
      "REAL",
    );

    await repairColumn(
      "lengthUpto",
      "REAL",
    );

    await repairColumn(
      "girthFrom",
      "REAL",
    );

    await repairColumn(
      "girthUpto",
      "REAL",
    );

    await repairColumn(
      "ratePerPole",
      "REAL",
    );

    await repairColumn(
      "category",
      "TEXT",
    );

    await repairColumn(
      "ratePerTon",
      "REAL",
    );
  }

// ============================================================
// VERSION 21
// DRFO ASSIGNMENT / ORDER DATE
// ============================================================

if (oldVersion < 21) {
  await db.execute(
    "ALTER TABLE applications "
    "ADD COLUMN drfoAssignmentDate TEXT",
  );
}

// ============================================================
// VERSION 22
// GOVERNMENT / PRIVATE APPLICATION ADDITIONAL DETAILS
// ============================================================

if (oldVersion < 22) {
  final applicationColumns = await db.rawQuery(
    "PRAGMA table_info(applications)",
  );

  final existingApplicationColumns = applicationColumns
      .map((column) => column["name"]?.toString() ?? "")
      .toSet();

  Future<void> addApplicationColumn(
    String name,
    String definition,
  ) async {
    if (!existingApplicationColumns.contains(name)) {
      await db.execute(
        "ALTER TABLE applications ADD COLUMN $name $definition",
      );
      existingApplicationColumns.add(name);
    }
  }

  await addApplicationColumn(
    "governmentAgencyId",
    "INTEGER",
  );

  await addApplicationColumn(
    "urbanRuralId",
    "INTEGER",
  );

  await addApplicationColumn(
    "structureTypeId",
    "INTEGER",
  );

  await addApplicationColumn(
    "workName",
    "TEXT",
  );

  final applicationTypeColumns = await db.rawQuery(
    "PRAGMA table_info(application_type_master)",
  );

  final existingApplicationTypeColumns = applicationTypeColumns
      .map((column) => column["name"]?.toString() ?? "")
      .toSet();

  if (!existingApplicationTypeColumns.contains("kannadaName")) {
    await db.execute(
      "ALTER TABLE application_type_master "
      "ADD COLUMN kannadaName TEXT",
    );
  }

// Hide legacy GL from new application selection.
// Existing applications containing GL remain unchanged.
await db.update(
  "application_type_master",
  {
    "isActive": 0,
  },
  where: "shortCode = ?",
  whereArgs: ["GL"],
);

Future<int> ensureApplicationType({
  required String name,
  required String kannadaName,
  required String code,
  required int order,
}) async {
  final existing = await db.query(
    "application_type_master",
    columns: ["id"],
    where: "shortCode = ?",
    whereArgs: [code],
    limit: 1,
  );

  if (existing.isNotEmpty) {
    final id = existing.first["id"] as int;

    await db.update(
      "application_type_master",
      {
        "applicationType": name,
        "kannadaName": kannadaName,
        "displayOrder": order,
        "isActive": 1,
      },
      where: "id = ?",
      whereArgs: [id],
    );

    return id;
  }

  return await db.insert(
    "application_type_master",
    {
      "applicationType": name,
      "kannadaName": kannadaName,
      "shortCode": code,
      "displayOrder": order,
      "isActive": 1,
    },
  );
}

final stateGovernmentLandId =
    await ensureApplicationType(
  name: "State Government Land",
  kannadaName: "ರಾಜ್ಯ ಸರ್ಕಾರದ ಜಾಗ",
  code: "STGL",
  order: 1,
);

final centralGovernmentLandId =
    await ensureApplicationType(
  name: "Central Government Land",
  kannadaName: "ಕೇಂದ್ರ ಸರ್ಕಾರದ ಜಾಗ",
  code: "CGL",
  order: 2,
);

final permissionRows = await db.query(
  "permission_type_master",
  columns: ["id"],
  where: "permissionType = ?",
  whereArgs: ["Permission"],
  limit: 1,
);

if (permissionRows.isNotEmpty) {
  final permissionId =
      permissionRows.first["id"] as int;

  Future<void> ensurePermissionMapping(
    int applicationTypeId,
  ) async {
    final existingMapping = await db.query(
      "application_type_permission_mapping",
      columns: ["id"],
      where: "applicationTypeId = ?",
      whereArgs: [applicationTypeId],
      limit: 1,
    );

    if (existingMapping.isEmpty) {
      await db.insert(
        "application_type_permission_mapping",
        {
          "applicationTypeId": applicationTypeId,
          "permissionTypeId": permissionId,
        },
      );
    } else {
      await db.update(
        "application_type_permission_mapping",
        {
          "permissionTypeId": permissionId,
        },
        where: "applicationTypeId = ?",
        whereArgs: [applicationTypeId],
      );
    }
  }

  await ensurePermissionMapping(
    stateGovernmentLandId,
  );

  await ensurePermissionMapping(
    centralGovernmentLandId,
  );
}

}

// ============================================================
// VERSION 23
// ADDITIONAL APPLICATION DETAIL VERIFICATION
// ============================================================

if (oldVersion < 23) {
  final verificationColumns = await db.rawQuery(
    "PRAGMA table_info(application_verifications)",
  );

  final existingVerificationColumns =
      verificationColumns
          .map(
            (column) =>
                column["name"]?.toString() ?? "",
          )
          .toSet();

  Future<void> addVerificationColumn(
    String name,
    String definition,
  ) async {
    if (!existingVerificationColumns.contains(name)) {
      await db.execute(
        "ALTER TABLE application_verifications "
        "ADD COLUMN $name $definition",
      );

      existingVerificationColumns.add(name);
    }
  }

  await addVerificationColumn(
    "governmentAgencyCorrect",
    "INTEGER",
  );

  await addVerificationColumn(
    "urbanRuralCorrect",
    "INTEGER",
  );

  await addVerificationColumn(
    "structureTypeCorrect",
    "INTEGER",
  );

  await addVerificationColumn(
    "workNameCorrect",
    "INTEGER",
  );

  await addVerificationColumn(
    "governmentAgencyReason",
    "TEXT",
  );

  await addVerificationColumn(
    "urbanRuralReason",
    "TEXT",
  );

  await addVerificationColumn(
    "structureTypeReason",
    "TEXT",
  );

  await addVerificationColumn(
    "workNameReason",
    "TEXT",
  );
}

// ============================================================
// VERSION 24
// MAHAZAR BOUNDARY LOCATION DROPDOWNS
// ============================================================

if (oldVersion < 24) {
  final mahazarColumns = await db.rawQuery(
    "PRAGMA table_info(application_mahazar)",
  );

  final existingMahazarColumns = mahazarColumns
      .map(
        (column) =>
            column["name"]?.toString() ?? "",
      )
      .toSet();

  Future<void> addMahazarColumn(
    String name,
    String definition,
  ) async {
    if (!existingMahazarColumns.contains(name)) {
      await db.execute(
        "ALTER TABLE application_mahazar "
        "ADD COLUMN $name $definition",
      );

      existingMahazarColumns.add(name);
    }
  }

  await addMahazarColumn(
    "northLocationId",
    "INTEGER",
  );

  await addMahazarColumn(
    "eastLocationId",
    "INTEGER",
  );

  await addMahazarColumn(
    "southLocationId",
    "INTEGER",
  );

  await addMahazarColumn(
    "westLocationId",
    "INTEGER",
  );
}

// ============================================================
// VERSION 25
// WHY REMOVING, PURPOSE ID AND THREE-STATE VERIFICATION
// ============================================================

if (oldVersion < 25) {
  Future<Set<String>> tableColumns(
    String table,
  ) async {
    final columns = await db.rawQuery(
      "PRAGMA table_info($table)",
    );

    return columns
        .map(
          (column) =>
              column["name"]?.toString() ?? "",
        )
        .toSet();
  }

  final applicationColumns =
      await tableColumns("applications");

  Future<void> addApplicationColumn(
    String name,
    String definition,
  ) async {
    if (!applicationColumns.contains(name)) {
      await db.execute(
        "ALTER TABLE applications "
        "ADD COLUMN $name $definition",
      );

      applicationColumns.add(name);
    }
  }

  await addApplicationColumn(
    "purposeId",
    "INTEGER",
  );

  await addApplicationColumn(
    "whyRemovingId",
    "INTEGER",
  );

  final verificationColumns =
      await tableColumns(
    "application_verifications",
  );

  Future<void> addVerificationColumn(
    String name,
    String definition,
  ) async {
    if (!verificationColumns.contains(name)) {
      await db.execute(
        "ALTER TABLE application_verifications "
        "ADD COLUMN $name $definition",
      );

      verificationColumns.add(name);
    }
  }

  await addVerificationColumn(
    "whyRemovingCorrect",
    "INTEGER",
  );

  await addVerificationColumn(
    "purposeCorrect",
    "INTEGER",
  );

  await addVerificationColumn(
    "whyRemovingReason",
    "TEXT",
  );

  await addVerificationColumn(
    "purposeReason",
    "TEXT",
  );

  const statusColumns = [
    "applicationTypeStatus",
    "governmentAgencyStatus",
    "urbanRuralStatus",
    "whyRemovingStatus",
    "purposeStatus",
    "structureTypeStatus",
    "workNameStatus",
    "gpsStatus",
    "photosStatus",
    "documentsStatus",
  ];

  for (final column in statusColumns) {
    await addVerificationColumn(
      column,
      "TEXT",
    );
  }

  // Convert existing two-option verification into
  // the new three-option status columns.
  await db.execute('''
    UPDATE application_verifications
    SET
      applicationTypeStatus =
        CASE applicationTypeCorrect
          WHEN 1 THEN 'Correct'
          WHEN 0 THEN 'Re-inspect'
          ELSE NULL
        END,
      governmentAgencyStatus =
        CASE governmentAgencyCorrect
          WHEN 1 THEN 'Correct'
          WHEN 0 THEN 'Re-inspect'
          ELSE NULL
        END,
      urbanRuralStatus =
        CASE urbanRuralCorrect
          WHEN 1 THEN 'Correct'
          WHEN 0 THEN 'Re-inspect'
          ELSE NULL
        END,
      structureTypeStatus =
        CASE structureTypeCorrect
          WHEN 1 THEN 'Correct'
          WHEN 0 THEN 'Re-inspect'
          ELSE NULL
        END,
      workNameStatus =
        CASE workNameCorrect
          WHEN 1 THEN 'Correct'
          WHEN 0 THEN 'Re-inspect'
          ELSE NULL
        END,
      gpsStatus =
        CASE gpsCorrect
          WHEN 1 THEN 'Correct'
          WHEN 0 THEN 'Re-inspect'
          ELSE NULL
        END,
      photosStatus =
        CASE photosCorrect
          WHEN 1 THEN 'Correct'
          WHEN 0 THEN 'Re-inspect'
          ELSE NULL
        END,
      documentsStatus =
        CASE documentsCorrect
          WHEN 1 THEN 'Correct'
          WHEN 0 THEN 'Re-inspect'
          ELSE NULL
        END
  ''');
}

// ============================================================
// VERSION 26
// DEFAULT WHY REMOVING MASTER VALUES
// ============================================================

if (oldVersion < 26) {
  final whyRemovingDefaults = [
    {
      "masterType": "Why Removing",
      "value": "Dangerous tree/branch",
      "kannadaName": "ಅಪಾಯಕಾರಿ ಮರ/ಕೊಂಬೆ",
      "code": "Danger",
      "parentCode": "",
      "displayOrder": 1,
      "remarks": "",
      "isActive": 1,
    },
    {
      "masterType": "Why Removing",
      "value": "Self convenience",
      "kannadaName": "ಸ್ವಂತ ಅನುಕೂಲಕ್ಕಾಗಿ",
      "code": "Convinient",
      "parentCode": "",
      "displayOrder": 2,
      "remarks": "",
      "isActive": 1,
    },
    {
      "masterType": "Why Removing",
      "value": "Development work",
      "kannadaName": "ಅಭಿವೃದ್ಧಿ ಕಾಮಗಾರಿ",
      "code": "Works",
      "parentCode": "",
      "displayOrder": 3,
      "remarks": "",
      "isActive": 1,
    },
    {
      "masterType": "Why Removing",
      "value": "Financial benefit",
      "kannadaName": "ಆರ್ಥಿಕ ಲಾಭಕ್ಕಾಗಿ",
      "code": "Finance",
      "parentCode": "",
      "displayOrder": 4,
      "remarks": "",
      "isActive": 1,
    },
  ];

  for (final item in whyRemovingDefaults) {
    final existing = await db.query(
      "master_data",
      columns: ["id"],
      where: "masterType = ? AND code = ?",
      whereArgs: [
        item["masterType"],
        item["code"],
      ],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.insert(
        "master_data",
        item,
      );
    }
  }
}

// ============================================================
// VERSION 27
// TREE STATUS FOR EACH INSPECTED TREE
// ============================================================

if (oldVersion < 27) {
  final treeColumns = await db.rawQuery(
    "PRAGMA table_info(trees)",
  );

  final treeColumnNames = treeColumns
      .map(
        (column) =>
            column["name"]?.toString() ?? "",
      )
      .toSet();

  if (!treeColumnNames.contains("treeStatusId")) {
    await db.execute(
      "ALTER TABLE trees "
      "ADD COLUMN treeStatusId INTEGER",
    );
  }
}

// ============================================================
// VERSION 28
// INSPECTING OFFICER OVERALL REMARK MASTER
// ============================================================

if (oldVersion < 28) {
  final applicationColumns = await db.rawQuery(
    "PRAGMA table_info(applications)",
  );

  final existingColumns = applicationColumns
      .map(
        (column) =>
            column["name"]?.toString() ?? "",
      )
      .toSet();

  if (!existingColumns.contains(
    "overallRemarkId",
  )) {
    await db.execute(
      "ALTER TABLE applications "
      "ADD COLUMN overallRemarkId INTEGER",
    );
  }
}

// ============================================================
// VERSION 29
// DRFO VERIFICATION OF INSPECTING OFFICER OVERALL REMARK
// ============================================================

if (oldVersion < 29) {
  final verificationColumns = await db.rawQuery(
    "PRAGMA table_info(application_verifications)",
  );

  final existingVerificationColumns =
      verificationColumns
          .map(
            (column) =>
                column["name"]?.toString() ?? "",
          )
          .toSet();

  Future<void> addVerificationColumn(
    String name,
    String definition,
  ) async {
    if (!existingVerificationColumns.contains(name)) {
      await db.execute(
        "ALTER TABLE application_verifications "
        "ADD COLUMN $name $definition",
      );

      existingVerificationColumns.add(name);
    }
  }

  await addVerificationColumn(
    "overallRemarkCorrect",
    "INTEGER",
  );

  await addVerificationColumn(
    "overallRemarkReason",
    "TEXT",
  );

  await addVerificationColumn(
    "overallRemarkStatus",
    "TEXT",
  );
}

// ============================================================
// VERSION 30
// RFO ITEM-WISE APPROVAL
// ============================================================

if (oldVersion < 30) {
  await db.execute("""
  CREATE TABLE IF NOT EXISTS rfo_item_approvals(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    applicationId INTEGER NOT NULL,
    itemKey TEXT NOT NULL,
    itemId INTEGER NOT NULL DEFAULT 0,
    decision TEXT,
    reason TEXT,
    approvedBy TEXT,
    approvedDate TEXT,
    UNIQUE(applicationId, itemKey, itemId)
  )
  """);
}

// ============================================================
// VERSION 31
// RFO LETTER CONFIGURATION
// ============================================================

if (oldVersion < 31) {
  final officeColumns =
      await db.rawQuery(
    "PRAGMA table_info(office_configuration)",
  );

  final officeColumnNames = officeColumns
      .map(
        (column) =>
            column["name"]?.toString() ?? "",
      )
      .toSet();

  if (!officeColumnNames.contains("rangeEmail")) {
    await db.execute(
      "ALTER TABLE office_configuration "
      "ADD COLUMN rangeEmail TEXT",
    );
  }

  await db.execute('''
  CREATE TABLE IF NOT EXISTS rfo_letter_configuration(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    applicationTypeCode TEXT NOT NULL UNIQUE,
    letterNumber TEXT
  )
  ''');
}

// ============================================================
// VERSION 32
// RFO OFFICE LOGO
// ============================================================

if (oldVersion < 32) {
  final officeColumns =
      await db.rawQuery(
    "PRAGMA table_info(office_configuration)",
  );

  final officeColumnNames = officeColumns
      .map(
        (column) =>
            column["name"]?.toString() ?? "",
      )
      .toSet();

  if (!officeColumnNames.contains(
    "rfoOfficeLogoPath",
  )) {
    await db.execute(
      "ALTER TABLE office_configuration "
      "ADD COLUMN rfoOfficeLogoPath TEXT",
    );
  }
}

// ============================================================
// VERSION 33
// RANGE LOCATION FOR RFO LETTERHEAD
// ============================================================

if (oldVersion < 33) {
  final officeColumns =
      await db.rawQuery(
    "PRAGMA table_info(office_configuration)",
  );

  final officeColumnNames = officeColumns
      .map(
        (column) =>
            column["name"]?.toString() ?? "",
      )
      .toSet();

  if (!officeColumnNames.contains(
    "rangeLocation",
  )) {
    await db.execute(
      "ALTER TABLE office_configuration "
      "ADD COLUMN rangeLocation TEXT",
    );
  }
}

// ============================================================
// VERSION 34
// NON-RTC DEFERRED RFO LETTER RECIPIENTS
// ============================================================

if (oldVersion < 34) {
  await db.execute("""
  CREATE TABLE IF NOT EXISTS rfo_deferred_letter_recipients(
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    applicationId INTEGER NOT NULL,
    recipientKey TEXT NOT NULL,
    sourceId INTEGER,
    sourceKind TEXT NOT NULL DEFAULT 'SOURCE',
    recipientText TEXT NOT NULL,
    isPrimary INTEGER NOT NULL DEFAULT 0,
    displayOrder INTEGER NOT NULL DEFAULT 0,
    UNIQUE(
      applicationId,
      recipientKey
    )
  )
  """);
  await _ensureSyncColumn(
      db, 'rfo_deferred_letter_recipients', 'sourceKind', 'TEXT');
}

// ============================================================
// VERSION 40
// MULTI-DEVICE SYNC QUEUE + ROW TIMESTAMPS (Stage 1)
// Supabase is source of truth; local sqflite stays offline cache.
// ============================================================

if (oldVersion < 40) {
  await _createSyncQueueTable(db);
  await _ensureSyncColumn(db, 'applications', 'updatedAt', 'TEXT');
  await _ensureSyncColumn(db, 'trees', 'updatedAt', 'TEXT');
  await _ensureSyncColumn(db, 'users', 'authId', 'TEXT');
  await _ensureSyncColumn(db, 'users', 'updatedAt', 'TEXT');
}

// ============================================================
// VERSION 41
// STAGE 2: updatedAt ON ALL SYNCED TABLES + users.email
// Last-write-wins needs a timestamp on every pushed table.
// ============================================================

if (oldVersion < 41) {
  const synced = [
    'users',
    'applications',
    'trees',
    'section_master',
    'beat_master',
    'master_data',
    'pole_rate_master',
    'application_history',
    'office_configuration',
    'rfo_letter_configuration',
    'application_type_master',
    'permission_type_master',
    'application_type_permission_mapping',
    'application_tree_count_site',
    'application_tree_count',
    'application_mahazar',
    'revenue_opinion_master',
    'forwarded_source_master',
    'inspection_photos',
    'inspection_documents',
    'inspection_defer_reason_master',
    'inspection_deferred_reasons',
    'application_verifications',
    'application_forward_references',
    'tree_verifications',
    'rfo_item_approvals',
    'rfo_deferred_letter_recipients',
    'application_revenue_opinion',
    'tree_count_verification',
    'revenue_opinion_verification',
    'mahazar_verification',
    'revenue_reply_cycles',
    'tree_officer_master',
    'application_tree_officer',
    'officer_directory',
    'government_approvals',
  ];
  for (final table in synced) {
    await _ensureSyncColumn(db, table, 'updatedAt', 'TEXT');
  }
  await _ensureSyncColumn(db, 'users', 'email', 'TEXT');
  await _ensureSyncColumn(db, 'users', 'authId', 'TEXT');
}

// ============================================================
// VERSION 42
// KANNADA NAMES + DEFAULT ENTRIES FOR EMPTY MASTERS
// ============================================================

if (oldVersion < 42) {
  await _applyV42Defaults(db);
}

// ============================================================
// VERSION 43
// AGENCY KANNADA FIELDS + FORWARD-REF KIND + OFFICE COUNTER
// ============================================================

if (oldVersion < 43) {
  await _ensureSyncColumn(
      db, 'revenue_opinion_master', 'kannadaName', 'TEXT');
  await _ensureSyncColumn(
      db, 'revenue_opinion_master', 'kannadaDesignation', 'TEXT');
  await _ensureSyncColumn(
      db, 'revenue_opinion_master', 'kannadaOfficeAddress', 'TEXT');
  await _ensureSyncColumn(
      db, 'application_forward_references', 'sourceKind', 'TEXT');
  await _ensureSyncColumn(
      db, 'rfo_deferred_letter_recipients', 'sourceKind', 'TEXT');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS office_number_counter(
      id INTEGER PRIMARY KEY,
      last_number INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.insert(
    'office_number_counter',
    {'id': 1, 'last_number': 0},
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );

  // Backfill Kannada for the 4 seeded revenue opinions.
  const agencyKannada = {
    'Private Land': [
      'ಖಾಸಗಿ ಜಮೀನು',
      'ತಹಶೀಲ್ದಾರ್, ಮೈಸೂರು ತಾಲ್ಲೂಕು',
      'ಮಿನಿ ವಿಧಾನಸೌಧ, ನಜರಬಾದ್, ಮೈಸೂರು - 570010'
    ],
    'Government Land': [
      'ಸರ್ಕಾರಿ ಜಮೀನು',
      'ತಹಶೀಲ್ದಾರ್, ಮೈಸೂರು ತಾಲ್ಲೂಕು',
      'ಮಿನಿ ವಿಧಾನಸೌಧ, ನಜರಬಾದ್, ಮೈಸೂರು - 570010'
    ],
    'Deemed Forest': [
      'ಡೀಮ್ಡ್ ಅರಣ್ಯ',
      'ಜಿಲ್ಲಾಧಿಕಾರಿ, ಮೈಸೂರು',
      'ಜಿಲ್ಲಾಧಿಕಾರಿಗಳ ಕಛೇರಿ, ಮೈಸೂರು - 570001'
    ],
    'Not Required': ['ಅಗತ್ಯವಿಲ್ಲ', '', ''],
  };
  for (final entry in agencyKannada.entries) {
    await db.update(
      'revenue_opinion_master',
      {
        'kannadaName': entry.value[0],
        'kannadaDesignation': entry.value[1],
        'kannadaOfficeAddress': entry.value[2],
      },
      where:
          'revenueOpinion=? AND (kannadaName IS NULL OR kannadaName=?)',
      whereArgs: [entry.key, ''],
    );
  }
  // Existing forward references are classic sources.
  await db.execute(
    "UPDATE application_forward_references "
    "SET sourceKind='SOURCE' WHERE sourceKind IS NULL",
  );
  await db.execute(
    "UPDATE rfo_deferred_letter_recipients "
    "SET sourceKind='SOURCE' WHERE sourceKind IS NULL",
  );
}

// ============================================================
// VERSION 44
// FORWARD-REF RECEIVED DATE + SAVED DISPLAY NAME
// ============================================================

if (oldVersion < 44) {
  await _ensureSyncColumn(
      db, 'application_forward_references', 'receivedDate', 'TEXT');
  await _ensureSyncColumn(
      db, 'application_forward_references', 'sourceName', 'TEXT');
  await _ensureSyncColumn(
      db, 'application_verifications', 'deferredCorrect', 'INTEGER');
  await _ensureSyncColumn(
      db, 'application_verifications', 'deferredReason', 'TEXT');
}

// ============================================================
// VERSION 45
// RTC ROWS WITHOUT PERMISSION TYPE GO TO TREE COUNT
// ============================================================

if (oldVersion < 45) {
  int? treeCountId;
  final types = await db.query(
    'permission_type_master',
    columns: ['id'],
    where: 'permissionType=?',
    whereArgs: ['Tree Count'],
    limit: 1,
  );
  if (types.isNotEmpty) {
    treeCountId = types.first['id'] as int?;
  }
  await db.update(
    'applications',
    {
      'permissionType': 'Tree Count',
      if (treeCountId != null) 'permissionTypeId': treeCountId,
    },
    where:
        "TRIM(UPPER(applicationType))='RTC' AND "
        "(permissionType IS NULL OR TRIM(permissionType)='')",
  );
}

// ============================================================
// VERSION 46
// DEFERRED VERIFICATION PERSISTENCE
// ============================================================

if (oldVersion < 46) {
  await _ensureSyncColumn(
      db, 'application_verifications', 'deferredCorrect', 'INTEGER');
  await _ensureSyncColumn(
      db, 'application_verifications', 'deferredReason', 'TEXT');
}

}

Future<void> _ensureFreshSyncColumns(DatabaseExecutor db) async {
  const synced = [
    'users',
    'applications',
    'trees',
    'section_master',
    'beat_master',
    'master_data',
    'pole_rate_master',
    'application_history',
    'office_configuration',
    'rfo_letter_configuration',
    'application_type_master',
    'permission_type_master',
    'application_type_permission_mapping',
    'application_tree_count_site',
    'application_tree_count',
    'application_mahazar',
    'revenue_opinion_master',
    'forwarded_source_master',
    'inspection_photos',
    'inspection_documents',
    'inspection_defer_reason_master',
    'inspection_deferred_reasons',
    'application_verifications',
    'application_forward_references',
    'tree_verifications',
    'rfo_item_approvals',
    'rfo_deferred_letter_recipients',
    'application_revenue_opinion',
    'tree_count_verification',
    'revenue_opinion_verification',
    'mahazar_verification',
    'revenue_reply_cycles',
    'tree_officer_master',
    'application_tree_officer',
    'officer_directory',
    'government_approvals',
  ];
  for (final table in synced) {
    await _ensureSyncColumn(db, table, 'updatedAt', 'TEXT');
  }
  await _ensureSyncColumn(db, 'users', 'email', 'TEXT');
  await _ensureSyncColumn(db, 'users', 'authId', 'TEXT');
  await _ensureSyncColumn(db, 'section_master', 'kannadaName', 'TEXT');
  await _ensureSyncColumn(db, 'beat_master', 'kannadaName', 'TEXT');
  await _ensureSyncColumn(
      db, 'revenue_opinion_master', 'kannadaName', 'TEXT');
  await _ensureSyncColumn(
      db, 'revenue_opinion_master', 'kannadaDesignation', 'TEXT');
  await _ensureSyncColumn(
      db, 'revenue_opinion_master', 'kannadaOfficeAddress', 'TEXT');
  await _ensureSyncColumn(
      db, 'application_forward_references', 'sourceKind', 'TEXT');
}

/// Default master entries with Kannada names, used by v42 upgrade.
/// Each entry: masterType, value, code, parentCode, displayOrder.
static const _v42MasterDefaults = [
  ['Government Agency', 'Forest Department', 'FOREST', '', 1],
  ['Government Agency', 'Revenue Department', 'REVENUE', '', 2],
  ['Government Agency', 'Public Works Department', 'PWD', '', 3],
  ['Urban Rural', 'Urban', 'URBAN', '', 1],
  ['Urban Rural', 'Rural', 'RURAL', '', 2],
  ['Urban Rural', 'Semi-Urban', 'SEMI', '', 3],
  ['Structure Type', 'Building', 'BUILDING', '', 1],
  ['Structure Type', 'Road', 'ROAD', '', 2],
  ['Structure Type', 'Layout', 'LAYOUT', '', 3],
  ['Tree Status', 'Healthy', 'HEALTHY', '', 1],
  ['Tree Status', 'Dead', 'DEAD', '', 2],
  ['Tree Status', 'Dangerous', 'DANGEROUS', '', 3],
  ['Tree Status', 'Diseased', 'DISEASED', '', 4],
  [
    'Inspecting Officer Overall Remark',
    'Recommended',
    'RECOMMENDED',
    '',
    1
  ],
  [
    'Inspecting Officer Overall Remark',
    'Not Recommended',
    'NOT_RECOMMENDED',
    '',
    2
  ],
  [
    'Inspecting Officer Overall Remark',
    'Need Re-inspection',
    'REINSPECT',
    '',
    3
  ],
  ['Mahazar Location', 'East', 'EAST', '', 1],
  ['Mahazar Location', 'West', 'WEST', '', 2],
  ['Mahazar Location', 'North', 'NORTH', '', 3],
  ['Mahazar Location', 'South', 'SOUTH', '', 4],
];

Future<void> _applyV42Defaults(DatabaseExecutor db) async {
  await _ensureSyncColumn(db, 'section_master', 'kannadaName', 'TEXT');
  await _ensureSyncColumn(db, 'beat_master', 'kannadaName', 'TEXT');

  // Sections: backfill Kannada, ensure a third default section.
  final sections = await db.query('section_master');
  for (final section in sections) {
    final kannada = section['kannadaName']?.toString() ?? '';
    if (kannada.isEmpty) {
      final name = section['sectionName']?.toString() ?? '';
      await db.update(
        'section_master',
        {'kannadaName': MasterKannada.forEntry('Section', name)},
        where: 'id=?',
        whereArgs: [section['id']],
      );
    }
  }
  if (sections.length < 3) {
    final existing = await db.query(
      'section_master',
      where: 'sectionName=?',
      whereArgs: ['Mysuru South'],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert('section_master', {
        'sectionName': 'Mysuru South',
        'kannadaName': 'ಮೈಸೂರು ದಕ್ಷಿಣ',
        'displayOrder': sections.length + 1,
        'isActive': 1,
      });
    }
  }

  // Beats: backfill Kannada.
  final beats = await db.query('beat_master');
  for (final beat in beats) {
    final kannada = beat['kannadaName']?.toString() ?? '';
    if (kannada.isEmpty) {
      final name = beat['beatName']?.toString() ?? '';
      await db.update(
        'beat_master',
        {'kannadaName': MasterKannada.forEntry('Beat', name)},
        where: 'id=?',
        whereArgs: [beat['id']],
      );
    }
  }

  // master_data: insert missing default types, backfill Kannada.
  for (final entry in _v42MasterDefaults) {
    final existing = await db.query(
      'master_data',
      columns: ['id'],
      where: 'masterType=? AND value=?',
      whereArgs: [entry[0], entry[1]],
      limit: 1,
    );
    if (existing.isEmpty) {
      await db.insert('master_data', {
        'masterType': entry[0],
        'value': entry[1],
        'code': entry[2],
        'parentCode': entry[3],
        'displayOrder': entry[4],
        'remarks': '',
        'kannadaName':
            MasterKannada.forEntry(entry[0] as String, entry[1] as String),
        'isActive': 1,
      });
    }
  }
  // Purpose ↔ Why Removing mapping: parentCode = reason code.
  const purposeParents = {
    'House Construction': 'CONVINIENT',
    'Agriculture': 'FINANCE',
    'Road Widening': 'WORKS',
  };
  for (final mapEntry in purposeParents.entries) {
    await db.update(
      'master_data',
      {'parentCode': mapEntry.value},
      where: 'masterType=? AND value=?',
      whereArgs: ['Purpose', mapEntry.key],
    );
  }
  final safety = await db.query(
    'master_data',
    columns: ['id'],
    where: 'masterType=? AND value=?',
    whereArgs: ['Purpose', 'Safety'],
    limit: 1,
  );
  if (safety.isEmpty) {
    await db.insert('master_data', {
      'masterType': 'Purpose',
      'value': 'Safety',
      'code': 'SAFETY',
      'parentCode': 'DANGER',
      'displayOrder': 4,
      'remarks': '',
      'kannadaName': 'ಸುರಕ್ಷತೆ',
      'isActive': 1,
    });
  }

  for (final mapEntry in MasterKannada.names.entries) {
    final parts = mapEntry.key.split('|');
    if (parts.length != 2) continue;
    await db.update(
      'master_data',
      {'kannadaName': mapEntry.value},
      where:
          'masterType=? AND value=? AND (kannadaName IS NULL OR kannadaName=?)',
      whereArgs: [parts[0], parts[1], ''],
    );
  }
}

Future<void> _createOfficeCounterTable(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS office_number_counter(
      id INTEGER PRIMARY KEY,
      last_number INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.insert(
    'office_number_counter',
    {'id': 1, 'last_number': 0},
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}

Future<void> _createSyncQueueTable(DatabaseExecutor db) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS sync_queue(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      tableName TEXT NOT NULL,
      localId INTEGER NOT NULL,
      operation TEXT NOT NULL DEFAULT 'upsert',
      createdAt TEXT NOT NULL
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_sync_queue_table '
    'ON sync_queue(tableName, localId)',
  );
}

Future<void> _ensureSyncColumn(
  DatabaseExecutor db,
  String table,
  String column,
  String definition,
) async {
  final cols = await db.rawQuery('PRAGMA table_info($table)');
  final names = cols
      .map((c) => c['name']?.toString() ?? '')
      .toSet();
  if (!names.contains(column)) {
    await db.execute(
      'ALTER TABLE $table ADD COLUMN $column $definition',
    );
  }
}

Future<void> _createTreeCountVerificationTable(
    Database db) async {

  await db.execute("""

CREATE TABLE tree_count_verification(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationId INTEGER,

verification TEXT,

reason TEXT,

verifiedBy TEXT,

verifiedDate TEXT

)

""");

}

Future<void> _createRevenueOpinionVerificationTable(
    Database db) async {

  await db.execute("""

CREATE TABLE revenue_opinion_verification(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationId INTEGER,

verification TEXT,

reason TEXT,

verifiedBy TEXT,

verifiedDate TEXT

)

""");

}

Future<void> _createMahazarVerificationTable(
    Database db) async {

  await db.execute("""

CREATE TABLE mahazar_verification(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationId INTEGER,

verification TEXT,

reason TEXT,

verifiedBy TEXT,

verifiedDate TEXT

)

""");

}

Future<void> seedDevelopmentData(Database db) async {

  // =====================================================
  // OFFICE CONFIGURATION
  // =====================================================

  await db.insert(
    "office_configuration",
    {
      "rangeName": "Mysuru Range",
      "rangeCode": "MYR",
      "officePrefix": "MYR",
      "financialYear": "2026-27",
      "rangeOfficeAddress": "Range Forest Office, Mysuru",
      "division": "Mysuru Division",
      "subDivision": "Mysuru Sub Division",
    },
  );

  // =====================================================
  // USERS
  // =====================================================

  final users = [

    {
      "name": "System Administrator",
      "username": "admin",
      "password": "admin123",
      "role": "RFO",
      "sectionId": null,
      "beatId": null,
      "isActive": 1,
    },

    {
      "name": "Range Forest Officer",
      "username": "rfo",
      "password": "1234",
      "role": "RFO",
      "sectionId": null,
      "beatId": null,
      "isActive": 1,
    },

    {
      "name": "Deputy Range Forest Officer",
      "username": "drfo",
      "password": "1234",
      "role": "DRFO",
      "sectionId": 1,
      "beatId": null,
      "isActive": 1,
    },

    {
      "name": "Beat Forest Officer",
      "username": "bfo1",
      "password": "1234",
      "role": "BFO",
      "sectionId": 1,
      "beatId": 1,
      "isActive": 1,
    },

    {
      "name": "Case Worker",
      "username": "caseworker",
      "password": "1234",
      "role": "Case Worker",
      "sectionId": null,
      "beatId": null,
      "isActive": 1,
    },

  ];

  for (final user in users) {
    await db.insert("users", user);
  }

  // =====================================================
  // SECTIONS
  // =====================================================

  await db.insert(
    "section_master",
    {
      "sectionName": "Mysuru Urban",
      "kannadaName": "ಮೈಸೂರು ನಗರ",
      "displayOrder": 1,
      "isActive": 1,
    },
  );

  await db.insert(
    "section_master",
    {
      "sectionName": "Mysuru Rural",
      "kannadaName": "ಮೈಸೂರು ಗ್ರಾಮಾಂತರ",
      "displayOrder": 2,
      "isActive": 1,
    },
  );

  await db.insert(
    "section_master",
    {
      "sectionName": "Mysuru South",
      "kannadaName": "ಮೈಸೂರು ದಕ್ಷಿಣ",
      "displayOrder": 3,
      "isActive": 1,
    },
  );

  // =====================================================
  // BEATS
  // =====================================================

  final beats = [

    {
      "sectionId": 1,
      "beatName": "Nazarbad",
      "kannadaName": "ನಜರಬಾದ್",
      "displayOrder": 1,
      "isActive": 1,
    },

    {
      "sectionId": 1,
      "beatName": "Siddarthanagar",
      "kannadaName": "ಸಿದ್ಧಾರ್ಥನಗರ",
      "displayOrder": 2,
      "isActive": 1,
    },

    {
      "sectionId": 2,
      "beatName": "Chamundi",
      "kannadaName": "ಚಾಮುಂಡಿ",
      "displayOrder": 1,
      "isActive": 1,
    },

    {
      "sectionId": 2,
      "beatName": "Yelwala",
      "kannadaName": "ಯಳವಳ",
      "displayOrder": 2,
      "isActive": 1,
    },

  ];

  for (final beat in beats) {
    await db.insert("beat_master", beat);
  }

  // =====================================================
  // APPLICATION TYPES
  // =====================================================

 final applicationTypes = [
  {
    "applicationType": "State Government Land",
    "kannadaName": "ರಾಜ್ಯ ಸರ್ಕಾರದ ಜಾಗ",
    "shortCode": "STGL",
    "displayOrder": 1,
    "isActive": 1,
  },
  {
    "applicationType": "Central Government Land",
    "kannadaName": "ಕೇಂದ್ರ ಸರ್ಕಾರದ ಜಾಗ",
    "shortCode": "CGL",
    "displayOrder": 2,
    "isActive": 1,
  },
  {
    "applicationType": "Private Land",
    "kannadaName": "ಖಾಸಗಿ ಜಾಗ",
    "shortCode": "PL",
    "displayOrder": 3,
    "isActive": 1,
  },
  {
    "applicationType": "RTC Entry",
    "kannadaName": "ಆರ್‌ಟಿಸಿ ನಮೂದು",
    "shortCode": "RTC",
    "displayOrder": 4,
    "isActive": 1,
  },
  {
    "applicationType": "MCC",
    "kannadaName": "ಮೈಸೂರು ಮಹಾನಗರ ಪಾಲಿಕೆ",
    "shortCode": "MCC",
    "displayOrder": 5,
    "isActive": 1,
  },
  {
    "applicationType": "Sandal Government",
    "kannadaName": "ಸರ್ಕಾರಿ ಶ್ರೀಗಂಧ",
    "shortCode": "SGL",
    "displayOrder": 6,
    "isActive": 1,
  },
  {
    "applicationType": "Sandal Private",
    "kannadaName": "ಖಾಸಗಿ ಶ್ರೀಗಂಧ",
    "shortCode": "SPL",
    "displayOrder": 7,
    "isActive": 1,
  },
];

  for (final type in applicationTypes) {
    await db.insert(
      "application_type_master",
      type,
    );
  }

// =====================================================
// PERMISSION TYPES
// =====================================================

final permissionTypes = [

  {
    "permissionType": "Permission",
    "displayOrder": 1,
    "isActive": 1,
  },

  {
    "permissionType": "Valuation",
    "displayOrder": 2,
    "isActive": 1,
  },

  {
    "permissionType": "Tree Count",
    "displayOrder": 3,
    "isActive": 1,
  },

  {
    "permissionType": "Forward to Tree Officer",
    "displayOrder": 4,
    "isActive": 1,
  },

  {
    "permissionType": "Auction",
    "displayOrder": 5,
    "isActive": 1,
  },

  {
    "permissionType": "Sandal Depot",
    "displayOrder": 6,
    "isActive": 1,
  },

];

for (final permission in permissionTypes) {

  await db.insert(
    "permission_type_master",
    permission,
  );

}

// =====================================================
// DEFAULT APPLICATION TYPE → PERMISSION TYPE MAPPING
// =====================================================

Future<int?> findApplicationTypeId(
  String shortCode,
) async {
  final result = await db.query(
    "application_type_master",
    columns: ["id"],
    where: "shortCode = ?",
    whereArgs: [shortCode],
    limit: 1,
  );

  if (result.isEmpty) return null;
  return result.first["id"] as int;
}

Future<int?> findPermissionTypeId(
  String permissionType,
) async {
  final result = await db.query(
    "permission_type_master",
    columns: ["id"],
    where: "permissionType = ?",
    whereArgs: [permissionType],
    limit: 1,
  );

  if (result.isEmpty) return null;
  return result.first["id"] as int;
}

Future<void> addDefaultMapping(
  String applicationCode,
  String permissionName,
) async {
  final applicationTypeId =
      await findApplicationTypeId(applicationCode);

  final permissionTypeId =
      await findPermissionTypeId(permissionName);

  if (applicationTypeId == null ||
      permissionTypeId == null) {
    return;
  }

  await db.insert(
    "application_type_permission_mapping",
    {
      "applicationTypeId": applicationTypeId,
      "permissionTypeId": permissionTypeId,
    },
  );
}

await addDefaultMapping("STGL", "Permission");
await addDefaultMapping("CGL", "Permission");
await addDefaultMapping("PL", "Permission");
await addDefaultMapping("RTC", "Tree Count");
await addDefaultMapping("MCC", "Permission");
await addDefaultMapping("SGL", "Sandal Depot");
await addDefaultMapping("SPL", "Valuation");

  // =====================================================
// FORWARDED SOURCES
// =====================================================

final forwardedSources = [

  {
    "sourceName": "DCF Office",
    "shortCode": "DCF",
    "displayOrder": 1,
    "isActive": 1,
  },

  {
    "sourceName": "ACF Office",
    "shortCode": "ACF",
    "displayOrder": 2,
    "isActive": 1,
  },

  {
    "sourceName": "MCC",
    "shortCode": "MCC",
    "displayOrder": 3,
    "isActive": 1,
  },

  {
    "sourceName": "MUDA",
    "shortCode": "MUDA",
    "displayOrder": 4,
    "isActive": 1,
  },

  {
    "sourceName": "NHAI",
    "shortCode": "NHAI",
    "displayOrder": 5,
    "isActive": 1,
  },

  {
    "sourceName": "BESCOM",
    "shortCode": "BESCOM",
    "displayOrder": 6,
    "isActive": 1,
  },

  {
    "sourceName": "KPTCL",
    "shortCode": "KPTCL",
    "displayOrder": 7,
    "isActive": 1,
  },

  {
    "sourceName": "PWD",
    "shortCode": "PWD",
    "displayOrder": 8,
    "isActive": 1,
  },

  {
    "sourceName": "Gram Panchayat",
    "shortCode": "GP",
    "displayOrder": 9,
    "isActive": 1,
  },

  {
    "sourceName": "Taluk Office",
    "shortCode": "TALUK",
    "displayOrder": 10,
    "isActive": 1,
  },

  {
    "sourceName": "Deputy Commissioner's Office",
    "shortCode": "DC",
    "displayOrder": 11,
    "isActive": 1,
  },

  {
    "sourceName": "Others",
    "shortCode": "OTHER",
    "displayOrder": 12,
    "isActive": 1,
  },

];

for (final source in forwardedSources) {

  await db.insert(
    "forwarded_source_master",
    source,
  );

}

// =====================================================
// INSPECTION DEFER REASONS
// =====================================================

final deferReasons = [

  {
    "reason": "Applicant Absent",
    "displayOrder": 1,
    "isActive": 1,
  },

  {
    "reason": "Heavy Rain",
    "displayOrder": 2,
    "isActive": 1,
  },

  {
    "reason": "Site Not Accessible",
    "displayOrder": 3,
    "isActive": 1,
  },

  {
    "reason": "Documents Not Available",
    "displayOrder": 4,
    "isActive": 1,
  },

  {
    "reason": "Owner Requested Postponement",
    "displayOrder": 5,
    "isActive": 1,
  },

  {
    "reason": "Law & Order Situation",
    "displayOrder": 6,
    "isActive": 1,
  },

  {
    "reason": "Court Stay",
    "displayOrder": 7,
    "isActive": 1,
  },

  {
    "reason": "Other",
    "displayOrder": 8,
    "isActive": 1,
  },

];

for (final reason in deferReasons) {

  await db.insert(
    "inspection_defer_reason_master",
    reason,
  );

}

}
}