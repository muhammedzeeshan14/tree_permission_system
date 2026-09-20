import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

enum PrivateLandOutcome { onlinePermission, applicantLetter, treeOfficerLetter }

class TreeOfficerRepository {
  static PrivateLandOutcome outcomeFor(Map<String, dynamic> officer) {
    final code = officer['code']?.toString().trim().toUpperCase();
    final requiresPermission = officer['requiresFellingPermission'];
    if (!{'RFO', 'ACF', 'DCF'}.contains(code) || !{0, 1}.contains(requiresPermission)) {
      throw StateError('Configure felling permission for the selected Tree Officer in Administration > Masters > Tree Officer.');
    }
    if (requiresPermission == 0) return PrivateLandOutcome.applicantLetter;
    return code == 'RFO' ? PrivateLandOutcome.onlinePermission : PrivateLandOutcome.treeOfficerLetter;
  }

  static Future<PrivateLandOutcome> completionOutcome(DatabaseExecutor db, int applicationId) async {
    final rows = await db.rawQuery(
      'SELECT m.* FROM application_tree_officer a JOIN tree_officer_master m ON m.id=a.treeOfficerId WHERE a.applicationId=?',
      [applicationId],
    );
    if (rows.isEmpty) throw StateError('Select Tree officer before final approval.');
    return outcomeFor(rows.first);
  }

  Future<PrivateLandOutcome> getCompletionOutcome(int applicationId) async =>
      completionOutcome(await _db, applicationId);

  final Database? databaseOverride;
  TreeOfficerRepository({this.databaseOverride});
  Future<Database> get _db async => databaseOverride ?? await DatabaseHelper.instance.database;

  static Future<void> createTables(DatabaseExecutor db) async {
    await db.execute('CREATE TABLE IF NOT EXISTS tree_officer_master ('
        'id INTEGER PRIMARY KEY, code TEXT NOT NULL UNIQUE, name TEXT NOT NULL, '
        'requiresFellingPermission INTEGER CHECK(requiresFellingPermission IN (0, 1)))');
    await db.execute('CREATE TABLE IF NOT EXISTS application_tree_officer ('
        'applicationId INTEGER PRIMARY KEY, treeOfficerId INTEGER NOT NULL, '
        'FOREIGN KEY(treeOfficerId) REFERENCES tree_officer_master(id))');
    for (final entry in {1: 'RFO', 2: 'ACF', 3: 'DCF'}.entries) {
      await db.insert('tree_officer_master', {'id':entry.key, 'code':entry.value, 'name':entry.value},
          conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<List<Map<String, dynamic>>> getAll() async => (await _db).query('tree_officer_master', orderBy:'id');

  Future<void> saveAll(List<Map<String, dynamic>> rows) async {
    if (rows.length != 3 || rows.map((r)=>r['id']).toSet().length != 3 ||
        rows.any((r)=> !{1,2,3}.contains(r['id']) ||
            (r['name']?.toString().trim() ?? '').isEmpty ||
            !{0,1}.contains(r['requiresFellingPermission']))) {
      throw ArgumentError('Enter all three officer names and select their felling permission mappings.');
    }
    final names = rows.map((r)=>r['name'].toString().trim().toUpperCase()).toSet();
    if (names.length != 3) throw ArgumentError('Officer names must be different.');
    await (await _db).transaction((txn) async {
      for (final row in rows) {
        await txn.update('tree_officer_master', {
          'name':row['name'].toString().trim(),
          'requiresFellingPermission':row['requiresFellingPermission'],
        }, where:'id=?', whereArgs:[row['id']]);
      }
    });
  }

  Future<int?> getSelection(int applicationId) async {
    final rows = await (await _db).query('application_tree_officer', where:'applicationId=?', whereArgs:[applicationId]);
    return rows.isEmpty ? null : rows.first['treeOfficerId'] as int;
  }

  Future<void> saveSelection(int applicationId, int officerId) async {
    final db=await _db;
    await db.transaction((txn) async {
      final applications=await txn.query('applications', columns:['applicationType'], where:'id=?', whereArgs:[applicationId]);
      if (applications.isEmpty || !{'PL','SPL'}.contains(applications.first['applicationType']?.toString().trim().toUpperCase())) {
        throw StateError('Tree officer selection is available for private-land applications only.');
      }
      if ((await txn.query('tree_officer_master',where:'id=?',whereArgs:[officerId])).isEmpty) {
        throw ArgumentError('Select a valid tree officer.');
      }
      await txn.insert('application_tree_officer', {'applicationId':applicationId,'treeOfficerId':officerId}, conflictAlgorithm:ConflictAlgorithm.replace);
    });
  }
}
