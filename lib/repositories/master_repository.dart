import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';
import '../constants/master_kannada.dart';

class MasterRepository {

  final DatabaseHelper dbHelper = DatabaseHelper.instance;

  Future<Database> get _db async =>
      await dbHelper.database;

  Future<List<Map<String, dynamic>>> getMasters(
      String masterType) async {

    final db = await _db;

    return await db.query(

      "master_data",

      where: "masterType=?",

      whereArgs: [masterType],

      orderBy: "displayOrder ASC",

    );

  }

  Future<Map<String, dynamic>?> getMasterById(
  int? id,
) async {
  if (id == null) return null;

  final db = await _db;

  final result = await db.query(
    "master_data",
    where: "id = ?",
    whereArgs: [id],
    limit: 1,
  );

  if (result.isEmpty) return null;

  return result.first;
}

  Future<void> insert({

    required String masterType,

    required String value,

    required String code,

    required int displayOrder,

    required String remarks,

    required bool isActive,
String parentCode = "",
String kannadaName = "",

  }) async {

    final db = await _db;

    await db.insert(

      "master_data",

      {

        "masterType": masterType,

        "value": value,

        "code": code,

        "parentCode": parentCode,

        "displayOrder": displayOrder,

        "remarks": remarks,

        "kannadaName": kannadaName,

        "isActive": isActive ? 1 : 0,

      },

    );

  }

  Future<void> update({

    required int id,

    required String value,

    required String code,

    required int displayOrder,

    required String remarks,

    required bool isActive,
String parentCode = "",
String kannadaName = "",

  }) async {

    final db = await _db;

    await db.update(

      "master_data",

      {

        "value": value,

        "code": code,

        "parentCode": parentCode,

        "displayOrder": displayOrder,

        "remarks": remarks,

        "kannadaName": kannadaName,

        "isActive": isActive ? 1 : 0,

      },

      where: "id=?",

      whereArgs: [id],

    );

  }

  Future<void> delete(int id) async {

    final db = await _db;

    await db.delete(

      "master_data",

      where: "id=?",

      whereArgs: [id],

    );

  }
  // ======================================
// SPECIES
// ======================================

Future<List<Map<String, dynamic>>> getSpecies() async {

  return await getMasters("Species");

}

// ======================================================
// POLE SPECIES
// ======================================================

Future<List<Map<String, dynamic>>> getPoleSpecies() async {
  final db = await _db;

  return await db.query(
    "master_data",
    where: "masterType=? AND speciesGroup=?",
    whereArgs: ["Species", "POLE"],
    orderBy: "displayOrder ASC",
  );
}

Future<void> insertPoleSpecies({
  required String species,
  required String scientificName,
  required String kannadaName,
  required int displayOrder,
  required bool isActive,
}) async {
  final db = await _db;

  await db.insert(
    "master_data",
    {
      "masterType": "Species",
      "value": species,
      "code": species.toUpperCase(),
      "parentCode": "",
      "displayOrder": displayOrder,
      "remarks": "",
      "isActive": isActive ? 1 : 0,
      "speciesGroup": "POLE",
      "scientificName": scientificName,
      "kannadaName": kannadaName,
    },
  );
}

Future<void> updatePoleSpecies({
  required int id,
  required String species,
  required String scientificName,
  required String kannadaName,
  required int displayOrder,
  required bool isActive,
}) async {
  final db = await _db;

  await db.update(
    "master_data",
    {
      "value": species,
      "code": species.toUpperCase(),
      "displayOrder": displayOrder,
      "remarks": "",
      "isActive": isActive ? 1 : 0,
      "speciesGroup": "POLE",
      "scientificName": scientificName,
      "kannadaName": kannadaName,
    },
    where: "id=?",
    whereArgs: [id],
  );
}

Future<void> deletePoleSpecies(int id) async {
  final db = await _db;

  await db.delete(
    "master_data",
    where: "id=?",
    whereArgs: [id],
  );
}

// ======================================================
// POLE RATE MASTER
// ======================================================

Future<List<Map<String, dynamic>>> getPoleRates(
  int speciesId,
) async {
  final db = await _db;

  return await db.query(
    "pole_rate_master",
    where: "speciesId=? AND isActive=1",
    whereArgs: [speciesId],
    orderBy: "lengthFrom ASC, girthFrom ASC, displayOrder ASC",
  );
}

Future<List<Map<String, dynamic>>> getAllPoleRates(
  int speciesId,
) async {
  final db = await _db;

  return await db.query(
    "pole_rate_master",
    where: "speciesId=?",
    whereArgs: [speciesId],
    orderBy: "lengthFrom ASC, girthFrom ASC, displayOrder ASC",
  );
}

Future<void> insertPoleRate({
  required int speciesId,
  required double lengthFrom,
  required double lengthUpto,
  required double girthFrom,
  required double girthUpto,
  required double rate,
  required String category,
  required int displayOrder,
  required bool isActive,
}) async {
  final db = await _db;

  await db.insert(
    "pole_rate_master",
    {
      "speciesId": speciesId,
      "lengthFrom": lengthFrom,
      "lengthUpto": lengthUpto,
      "girthFrom": girthFrom,
      "girthUpto": girthUpto,
      "rate": rate,
      "category": category,
      "displayOrder": displayOrder,
      "isActive": isActive ? 1 : 0,
    },
  );
}

Future<void> updatePoleRate({
  required int id,
  required int speciesId,
  required double lengthFrom,
  required double lengthUpto,
  required double girthFrom,
  required double girthUpto,
  required double rate,
  required String category,
  required int displayOrder,
  required bool isActive,
}) async {
  final db = await _db;

  await db.update(
    "pole_rate_master",
    {
      "speciesId": speciesId,
      "lengthFrom": lengthFrom,
      "lengthUpto": lengthUpto,
      "girthFrom": girthFrom,
      "girthUpto": girthUpto,
      "rate": rate,
      "category": category,
      "displayOrder": displayOrder,
      "isActive": isActive ? 1 : 0,
    },
    where: "id=?",
    whereArgs: [id],
  );
}

Future<void> deletePoleRate(int id) async {
  final db = await _db;

  await db.delete(
    "pole_rate_master",
    where: "id=?",
    whereArgs: [id],
  );
}

Future<List<Map<String, dynamic>>> getSpeciesByGroup(
  String group,
) async {
  final db = await _db;

  return await db.query(
    "master_data",
    where: "masterType=? AND speciesGroup=?",
    whereArgs: [
      "Species",
      group,
    ],
    orderBy: "displayOrder ASC",
  );
}

Future<void> insertSpecies({
  required String speciesGroup,
  required String species,
  required String scientificName,
  required String kannadaName,
  double? ratePerCubicMeter,
  double? lengthFrom,
  double? lengthUpto,
  double? girthFrom,
  double? girthUpto,
  double? ratePerPole,
  String category = "",
  double? ratePerTon,
  required int displayOrder,
  required bool isActive,
}) async {
  final db = await _db;

  await db.insert(
    "master_data",
    {
      "masterType": "Species",
      "value": species,
      "code": species.toUpperCase(),
      "parentCode": "",
      "displayOrder": displayOrder,
      "remarks": "",
      "isActive": isActive ? 1 : 0,

      "speciesGroup": speciesGroup,
      "scientificName": scientificName,
      "kannadaName": kannadaName,

      "ratePerCubicMeter": ratePerCubicMeter,
      "lengthFrom": lengthFrom,
      "lengthUpto": lengthUpto,
      "girthFrom": girthFrom,
      "girthUpto": girthUpto,
      "ratePerPole": ratePerPole,

      "category": category,
      "ratePerTon": ratePerTon,
    },
  );
}

Future<void> updateSpecies({
  required int id,
  required String speciesGroup,
  required String species,
  required String scientificName,
  required String kannadaName,
  double? ratePerCubicMeter,
  double? lengthFrom,
  double? lengthUpto,
  double? girthFrom,
  double? girthUpto,
  double? ratePerPole,
  String category = "",
  double? ratePerTon,
  required int displayOrder,
  required bool isActive,
}) async {
  final db = await _db;

  await db.update(
    "master_data",
    {
      "value": species,
      "code": species.toUpperCase(),

      "displayOrder": displayOrder,
      "remarks": "",
      "isActive": isActive ? 1 : 0,

      "speciesGroup": speciesGroup,
      "scientificName": scientificName,
      "kannadaName": kannadaName,

      "ratePerCubicMeter": ratePerCubicMeter,
      "lengthFrom": lengthFrom,
      "lengthUpto": lengthUpto,
      "girthFrom": girthFrom,
      "girthUpto": girthUpto,
      "ratePerPole": ratePerPole,

      "category": category,
      "ratePerTon": ratePerTon,
    },
    where: "id=?",
    whereArgs: [id],
  );
}

Future<double?> getFirewoodRate() async {

  final db = await _db;

  final result = await db.query(
    "master_data",
    where:
        "masterType=? AND speciesGroup=? AND isActive=1",
    whereArgs: [
      "Species",
      "FIREWOOD",
    ],
    limit: 1,
  );

  if (result.isEmpty) {
    return null;
  }

  return result.first["ratePerTon"] as double?;
}

Future<List<Map<String, dynamic>>> getRecommendationReasons(
  String recommendationCode,
) async {
  final db = await _db;

  return await db.query(
    "master_data",
    where: "masterType=? AND parentCode=? AND isActive=1",
    whereArgs: [
      "Recommendation Reason",
      recommendationCode,
    ],
    orderBy: "displayOrder",
  );
}

Future<List<String>> getVerificationReasons(
  String parentCode,
) async {
  final masters = await getMasters("Verification Reason");

  return masters
      .where(
        (e) =>
            e["parentCode"] == parentCode &&
            e["isActive"] == 1,
      )
      .map<String>((e) => e["value"] as String)
      .toList();
}

Future<void> loadDefaultMasters() async {

  final db = await _db;

  await db.delete("master_data");

  // TEMPORARY
  // Remove this after today's cleanup.

  final count = Sqflite.firstIntValue(
    await db.rawQuery(
      "SELECT COUNT(*) FROM master_data",
    ),
  ) ?? 0;

  if (count > 0) {
    return;
  }

  Future<void> add(
  String type,
  String value,
  String code,
  String parentCode,
  int order,
) async {
  await db.insert(
    "master_data",
    {
      "masterType": type,
      "value": value,
      "code": code,
      "parentCode": parentCode,
      "displayOrder": order,
      "remarks": "",
      "kannadaName": MasterKannada.forEntry(type, value),
      "isActive": 1,
    },
  );
}

  // SECTIONS

  await add("Section","Section-1","S1","",1);
await add("Section","Section-2","S2","",2);

  // BEATS

  await add("Beat","Beat-1","B1","",1);
await add("Beat","Beat-2","B2","",2);

  // PURPOSE (parentCode = Why Removing code for mapping)

  await add("Purpose","House Construction","HOUSE","CONVINIENT",1);
  await add("Purpose","Agriculture","AGRI","FINANCE",2);
  await add("Purpose","Road Widening","ROADW","WORKS",3);
  await add("Purpose","Safety","SAFETY","DANGER",4);

  // GOVERNMENT AGENCY

  await add("Government Agency","Forest Department","FOREST","",1);
  await add("Government Agency","Revenue Department","REVENUE","",2);
  await add("Government Agency","Public Works Department","PWD","",3);

  // URBAN RURAL

  await add("Urban Rural","Urban","URBAN","",1);
  await add("Urban Rural","Rural","RURAL","",2);
  await add("Urban Rural","Semi-Urban","SEMI","",3);

  // STRUCTURE TYPE

  await add("Structure Type","Building","BUILDING","",1);
  await add("Structure Type","Road","ROAD","",2);
  await add("Structure Type","Layout","LAYOUT","",3);

  // TREE STATUS

  await add("Tree Status","Healthy","HEALTHY","",1);
  await add("Tree Status","Dead","DEAD","",2);
  await add("Tree Status","Dangerous","DANGEROUS","",3);
  await add("Tree Status","Diseased","DISEASED","",4);

  // INSPECTING OFFICER OVERALL REMARK

  await add("Inspecting Officer Overall Remark","Recommended","RECOMMENDED","",1);
  await add("Inspecting Officer Overall Remark","Not Recommended","NOT_RECOMMENDED","",2);
  await add("Inspecting Officer Overall Remark","Need Re-inspection","REINSPECT","",3);

  // MAHAZAR LOCATION

  await add("Mahazar Location","East","EAST","",1);
  await add("Mahazar Location","West","WEST","",2);
  await add("Mahazar Location","North","NORTH","",3);
  await add("Mahazar Location","South","SOUTH","",4);

  // SPECIES

  await add("Species","Neem","NEEM","",1);
await add("Species","Honge","HONGE","",2);
await add("Species","Teak","TEAK","",3);
await add("Species","Mango","MANGO","",4);
await add("Species","Rain Tree","RAIN","",5);
await add("Species","Silver Oak","SILVER","",6);
await add("Species","Nilgiri","NILGIRI","",7);
await add("Species","Banyan","BANYAN","",8);
await add("Species","Peepal","PEEPAL","",9);
await add("Species","Tamarind","TAMARIND","",10);

  // PROBLEMS

  await add("Problem","Dangerous","","",1);
await add("Problem","Dead","","",2);
await add("Problem","Dry","","",3);

  // RECOMMENDATIONS

  await add("Recommendation Type","Full Tree","FULL","",1);

await add("Recommendation Type","Branches Only","BRANCH","",2);

await add("Recommendation Type","Twigs Only","TWIG","",3);

await add("Recommendation Type","Top Portion Above 20 Feet","TOP","",4);

await add("Recommendation Type","Not Recommended","NR","",5);

  // RECOMMENDATION REASONS

// FULL

await add("Recommendation Reason","Dead Tree","DEAD","FULL",1);

await add("Recommendation Reason","Diseased Tree","DISEASE","FULL",2);

await add("Recommendation Reason","Dangerous Tree","DANGER","FULL",3);

await add("Recommendation Reason","Leaning Tree","LEAN","FULL",4);

// BRANCH

await add("Recommendation Reason","Electric Line Clearance","LINE","BRANCH",1);

await add("Recommendation Reason","Building Clearance","BUILDING","BRANCH",2);

await add("Recommendation Reason","Road Clearance","ROAD","BRANCH",3);

await add("Recommendation Reason","Public Safety","SAFETY","BRANCH",4);

// TWIG

await add("Recommendation Reason","Routine Pruning","ROUTINE","TWIG",1);

await add("Recommendation Reason","Nursery Requirement","NURSERY","TWIG",2);

// TOP

await add("Recommendation Reason","Dry Top","DRYTOP","TOP",1);

await add("Recommendation Reason","Safety Clearance","SAFE","TOP",2);

// NR

await add("Recommendation Reason","Healthy Tree","HEALTHY","NR",1);

await add("Recommendation Reason","Heritage Tree","HERITAGE","NR",2);

await add("Recommendation Reason","Bird Nest Present","BIRDNEST","NR",3);

await add("Recommendation Reason","Religious Importance","RELIGIOUS","NR",4);

await add("Recommendation Reason","Others","OTHER","NR",5);


  // RETURN REASONS

  await add("Return Reason","Clarification Required","","",1);
await add("Return Reason","Documents Missing","","",2);

// INSPECTION DEFERRED REASONS

await add(
    "Inspection Deferred Reason",
    "Applicant Not Available",
    "",
    "",
    1);

await add(
    "Inspection Deferred Reason",
    "Site Not Traceable",
    "",
    "",
    2);

await add(
    "Inspection Deferred Reason",
    "Documents Not Available",
    "",
    "",
    3);

await add(
    "Inspection Deferred Reason",
    "Wrong Location",
    "",
    "",
    4);

await add(
    "Inspection Deferred Reason",
    "Tree Already Removed",
    "",
    "",
    5);

await add(
    "Inspection Deferred Reason",
    "Others",
    "",
    "",
    6);
    
  // STANDARD REMARKS

  await add("Standard Remark","Inspection Completed","","",1);
await add("Standard Remark","Verified","","",2);
// DOCUMENT TYPES

await add(
  "Document Type",
  "RTC",
  "",
  "",
  1,
);

await add(
  "Document Type",
  "Survey Sketch",
  "",
  "",
  2,
);

await add(
  "Document Type",
  "Aadhaar",
  "",
  "",
  3,
);

await add(
  "Document Type",
  "Revenue Certificate",
  "",
  "",
  4,
);

await add(
  "Document Type",
  "Ownership Proof",
  "",
  "",
  5,
);

await add(
  "Document Type",
  "Court Order",
  "",
  "",
  6,
);

await add(
  "Document Type",
  "Other",
  "",
  "",
  7,
);
// WORKFLOW STATUS

await add(
  "Workflow Status",
  "Draft",
  "DRAFT",
  "",
  1,
);

await add(
  "Workflow Status",
  "Pending BFO",
  "PBFO",
  "",
  2,
);

await add(
  "Workflow Status",
  "Pending DRFO",
  "PDRFO",
  "",
  3,
);

await add(
  "Workflow Status",
  "Pending RFO",
  "PRFO",
  "",
  4,
);

await add(
  "Workflow Status",
  "Returned by DRFO",
  "RDRFO",
  "",
  5,
);

await add(
  "Workflow Status",
  "Returned by RFO",
  "RRFO",
  "",
  6,
);

await add(
  "Workflow Status",
  "Approved",
  "APP",
  "",
  7,
);

await add(
  "Workflow Status",
  "Rejected",
  "REJ",
  "",
  8,
);

// ======================================================
// VERIFICATION REASONS
// ======================================================

// Application Type
await add(
  "Verification Reason",
  "Application Type Incorrect",
  "APPTYPE01",
  "APPLICATION_TYPE",
  1,
);

// GPS
await add(
  "Verification Reason",
  "GPS Location Incorrect",
  "GPS01",
  "GPS",
  1,
);

// Tree
await add(
  "Verification Reason",
  "Wrong Tree Details",
  "TREE01",
  "TREE",
  1,
);

await add(
  "Verification Reason",
  "Wrong Recommendation",
  "TREE02",
  "TREE",
  2,
);

// Photos
await add(
  "Verification Reason",
  "Required Photos Missing",
  "PHOTO01",
  "PHOTO",
  1,
);

// Documents
await add(
  "Verification Reason",
  "Required Documents Missing",
  "DOC01",
  "DOCUMENT",
  1,
);

// Deferred Inspection
await add(
  "Verification Reason",
  "Deferred Reason Incorrect",
  "DEFER01",
  "DEFERRED",
  1,
);

// ======================================================
// DOCUMENT MASTERS
// ======================================================

await add(
  "Document Master",
  "Tree Enumeration List",
  "ENUM",
  "ALL",
  1,
);

await add(
  "Document Master",
  "Mahazar",
  "MAHAZAR",
  "ALL",
  2,
);

await add(
  "Document Master",
  "Covering Letter",
  "COVER",
  "ALL",
  3,
);

await add(
  "Document Master",
  "Inspection Report",
  "REPORT",
  "ALL",
  4,
);

// ======================================================
// DOCUMENT TEMPLATES
// ======================================================

await add(
  "Document Template",
  "Enumeration Template",
  "ENUM_V1",
  "ENUM",
  1,
);

await add(
  "Document Template",
  "Mahazar Template",
  "MAHAZAR_V1",
  "MAHAZAR",
  2,
);

await add(
  "Document Template",
  "Cover Letter Template",
  "COVER_V1",
  "COVER",
  3,
);

await add(
  "Document Template",
  "Inspection Report Template",
  "REPORT_V1",
  "REPORT",
  4,
);

}
}