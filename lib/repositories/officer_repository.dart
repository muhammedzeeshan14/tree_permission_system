import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';

class OfficerRepository {
  final Database? databaseOverride;
  OfficerRepository({this.databaseOverride});
  Future<Database> get _db async => databaseOverride ?? await DatabaseHelper.instance.database;
  static const roles = ['RFO', 'ACF', 'DCF'];
  static Future<void> createTable(DatabaseExecutor db) async {
    await db.execute("CREATE TABLE IF NOT EXISTS officer_directory (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, designation TEXT NOT NULL, postingAddress TEXT NOT NULL, role TEXT NOT NULL UNIQUE CHECK(role IN ('RFO','ACF','DCF')))");
  }
  Future<List<Map<String,dynamic>>> getAll() async => (await _db).query('officer_directory',orderBy:'id');
  Future<void> save({int? id, required String name, required String designation, required String postingAddress, required String role}) async {
    if(name.trim().isEmpty || designation.trim().isEmpty || postingAddress.trim().isEmpty || !roles.contains(role)) {
      throw ArgumentError('Enter name, designation, posting address and role.');
    }
    final db=await _db;
    await db.transaction((tx) async {
      final duplicates=await tx.query('officer_directory',where:'role=? AND id<>?',whereArgs:[role,id??-1]);
      if(duplicates.isNotEmpty) throw StateError('An officer is already mapped to '+role+'. Edit that entry.');
      final row={'name':name.trim(),'designation':designation.trim(),'postingAddress':postingAddress.trim(),'role':role};
      if(id==null) {await tx.insert('officer_directory',row);} else {
        if(await tx.update('officer_directory',row,where:'id=?',whereArgs:[id])!=1) throw StateError('Officer not found.');
      }
    });
  }
  static String formatAddress(Map<String,dynamic> row,{bool copyTo=false}) {
    String line(String key) => (row[key]?.toString()??'').replaceAll(RegExp(r'\s+'),' ').trim();
    final designation=line('designation'), address=line('postingAddress');
    if(designation.isEmpty || address.isEmpty) throw StateError('Complete the officer designation and posting address in Administration > Officers.');
    return designation+(copyTo?', ':'\n')+address;
  }
  Future<String> addressForRole(String role,{bool copyTo=false}) async {
    final rows=await (await _db).query('officer_directory',where:'role=?',whereArgs:[role]);
    if(rows.isEmpty) throw StateError('Add the '+role+' officer in Administration > Officers before generating or printing this letter.');
    return formatAddress(rows.single,copyTo:copyTo);
  }
  Future<String?> sourceRole(int? sourceId,String fallback) async {
    if(sourceId!=null) {
      final rows=await (await _db).query('forwarded_source_master',where:'id=?',whereArgs:[sourceId]);
      if(rows.isNotEmpty) {
        final code=rows.first['shortCode']?.toString().trim().toUpperCase();
        if(code=='ACF'||code=='DCF') return code;
      }
    }
    final text=fallback.trim().toUpperCase();
    if(text=='ACF'||text=='ACF OFFICE') return 'ACF';
    if(text=='DCF'||text=='DCF OFFICE') return 'DCF';
    return null;
  }
  Future<String> sourceAddress(int? sourceId,String fallback,{bool copyTo=false}) async {
    final role=await sourceRole(sourceId,fallback);
    return role==null ? fallback : addressForRole(role,copyTo:copyTo);
  }
  Future<String> fingerprint() async => jsonEncode(await getAll());
}
