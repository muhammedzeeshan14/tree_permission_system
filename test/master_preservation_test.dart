import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tree_permission_system/repositories/master_repository.dart';

void main() {
  test('Loading defaults preserves edited master IDs used by existing trees', () async {
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    await db.execute('CREATE TABLE master_data(id INTEGER PRIMARY KEY, value TEXT)');
    await db.execute('CREATE TABLE trees(id INTEGER PRIMARY KEY, speciesId INTEGER)');
    await db.insert('master_data', {'id': 108, 'value': 'Edited species'});
    await db.insert('trees', {'id': 1, 'speciesId': 108});
    final before = await db.query('master_data');
    await MasterRepository(databaseOverride: db).loadDefaultMasters();
    expect(await db.query('master_data'), before);
    expect((await db.rawQuery('SELECT m.value FROM trees t JOIN master_data m ON m.id=t.speciesId')).single['value'], 'Edited species');
  });
}
