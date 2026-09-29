import 'package:sqflite/sqflite.dart';
import '../constants/timber_species_defaults.dart';

/// Initializes an empty timber group only. Reopening the app never overwrites
/// RFO changes or replaces IDs referenced by existing inspections.
Future<void> seedTimberSpeciesDefaults(DatabaseExecutor db) async {
  final existing = await db.query(
    'master_data',
    columns: ['id'],
    where: 'masterType=? AND speciesGroup=?',
    whereArgs: ['Species', 'TIMBER'],
    limit: 1,
  );
  if (existing.isNotEmpty) return;
  for (final row in timberSpeciesDefaults) {
    await db.insert('master_data', row);
  }
}
