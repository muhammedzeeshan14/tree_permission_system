import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tree_permission_system/constants/timber_species_defaults.dart';
import 'package:tree_permission_system/database/timber_species_seed.dart';

void main() {
  test(
    'Annexure has all 123 serials, positive cubic-metre rates and blank categories',
    () {
      expect(timberSpeciesDefaults.length, 123);
      expect(
        timberSpeciesDefaults.map((r) => r['displayOrder']),
        List.generate(123, (i) => i + 1),
      );
      expect(timberSpeciesDefaults.map((r) => r['code']).toSet().length, 123);
      for (final row in timberSpeciesDefaults) {
        expect(row['speciesGroup'], 'TIMBER');
        expect(row['category'], '');
        expect(row['isActive'], 1);
        expect(row['ratePerCubicMeter'] as num, greaterThan(0));
        for (final field in ['value', 'scientificName', 'kannadaName']) {
          expect((row[field] as String).trim(), isNotEmpty);
        }
      }
      expect(timberSpeciesDefaults[1]['ratePerCubicMeter'], 115125);
      expect(timberSpeciesDefaults[62]['ratePerCubicMeter'], 9362);
      expect(timberSpeciesDefaults[110]['ratePerCubicMeter'], 8909);
      for (final serial in [43, 98]) {
        expect(
          timberSpeciesDefaults[serial - 1]['value'],
          timberSpeciesDefaults[serial - 1]['scientificName'],
        );
      }
    },
  );
  test(
    'Seeding leaves other groups intact and does not reset edits on another run',
    () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute(
        '''CREATE TABLE master_data(id INTEGER PRIMARY KEY AUTOINCREMENT,
      masterType TEXT, value TEXT, code TEXT, parentCode TEXT, displayOrder INTEGER,
      remarks TEXT, isActive INTEGER, speciesGroup TEXT, scientificName TEXT,
      kannadaName TEXT, ratePerCubicMeter REAL, category TEXT)''',
      );
      for (final group in ['POLE', 'SANDAL', 'FIREWOOD']) {
        await db.insert('master_data', {
          'masterType': 'Species',
          'speciesGroup': group,
          'value': group,
        });
      }
      final otherBefore = await db.query('master_data');
      await db.transaction((tx) => seedTimberSpeciesDefaults(tx));
      expect((await db.query('master_data')).length, 126);
      expect(
        await db.query('master_data', where: "speciesGroup != 'TIMBER'"),
        otherBefore,
      );
      final teak = (await db.query(
        'master_data',
        where: 'code=?',
        whereArgs: ['TIMBER_2026_002'],
      )).single;
      await db.update(
        'master_data',
        {'value': 'RFO edited name', 'ratePerCubicMeter': 123},
        where: 'id=?',
        whereArgs: [teak['id']],
      );
      await db.transaction((tx) => seedTimberSpeciesDefaults(tx));
      expect((await db.query('master_data')).length, 126);
      final edited = (await db.query(
        'master_data',
        where: 'id=?',
        whereArgs: [teak['id']],
      )).single;
      expect(edited['value'], 'RFO edited name');
      expect(edited['ratePerCubicMeter'], 123);
    },
  );
}
