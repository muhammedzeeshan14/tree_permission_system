import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();

    return _database!;
  }

  static Future<Database> _initDatabase() async {
    String dbPath = await getDatabasesPath();

    return await openDatabase(
      join(dbPath, 'tpms.db'),
      version: 4,
      onCreate: _createDatabase,
    );
  }

  static Future<void> _createDatabase(
      Database db,
      int version,
      ) async {

    await db.execute('''
CREATE TABLE applications(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationNumber TEXT,

applicationType TEXT,

applicantName TEXT,

address TEXT,

phone TEXT,

surveyNumber TEXT,

village TEXT,

hobli TEXT,

taluk TEXT,

sectionName TEXT,

beatName TEXT,

createdDate TEXT,

status TEXT,

lastTreeNumber INTEGER DEFAULT 0

)

''');
await db.execute('''
CREATE TABLE trees(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationId INTEGER NOT NULL,

treeNumber TEXT NOT NULL,

baseTreeNumber INTEGER NOT NULL,

stemType TEXT NOT NULL,

stemLetter TEXT,

speciesId INTEGER NOT NULL,

recommendationTypeId INTEGER,

gbh REAL,

height REAL,

numberOfBranches INTEGER,

numberOfTwigs INTEGER,

firewood REAL NOT NULL,

recommendationReasonIds TEXT,

remarks TEXT

)
''');

await _createApplicationVerificationsTable(db);

await _createApplicationVerificationReasonsTable(db);

  }

static Future<void> _createApplicationVerificationsTable(
    Database db) async {
  await db.execute('''
CREATE TABLE application_verifications(

id INTEGER PRIMARY KEY AUTOINCREMENT,

applicationId INTEGER NOT NULL,

verificationType TEXT NOT NULL,

referenceId INTEGER DEFAULT 0,

verificationStatus TEXT NOT NULL,

remarks TEXT,

verifiedByUserId INTEGER,

verifiedDate TEXT

)
''');
}

static Future<void> _createApplicationVerificationReasonsTable(
    Database db) async {
  await db.execute('''
CREATE TABLE application_verification_reasons(

id INTEGER PRIMARY KEY AUTOINCREMENT,

verificationId INTEGER NOT NULL,

reasonMasterId INTEGER NOT NULL

)
''');
}

}