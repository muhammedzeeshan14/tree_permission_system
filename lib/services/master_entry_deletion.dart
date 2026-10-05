import '../database/database_helper.dart';
import 'online_database.dart';
import 'online_mode.dart';

class MasterEntryDeletion {
  static Future<List<Map<String,dynamic>>> _rows(String table) async => OnlineMode.enabled
      ? OnlineDatabase.selectAll(table)
      : (await DatabaseHelper.instance.database).query(table);
  static Future<void> delete(String table, int id) async {
    final references = <String,List<String>>{};
    if (table == 'master_data') {
      references.addAll({
        'applications': ['purposeId','whyRemovingId','governmentAgencyId','urbanRuralId','structureTypeId','overallRemarkId','sandalDestinationId'],
        'trees': ['speciesId','recommendationTypeId','treeStatusId','recommendationReasonIds','problemIds'],
        'application_tree_count': ['speciesId'],
        'application_mahazar': ['northLocationId','eastLocationId','southLocationId','westLocationId'],
        'pole_rate_master': ['speciesId'],
      });
    } else if (table == 'permission_type_master') {
      references.addAll({'applications':['permissionTypeId'], 'application_type_permission_mapping':['permissionTypeId']});
    } else if (table == 'application_type_master') {
      references['application_type_permission_mapping'] = ['applicationTypeId'];
      final master = (await _rows(table)).where((r) => r['id'] == id).firstOrNull;
      if (master != null && (await _rows('applications')).any((r) => r['applicationType'] == master['shortCode'] || r['applicationType'] == master['applicationType'])) throw StateError('Application type is already used. Deactivate it instead.');
    } else if (table == 'officer_directory') {
      if ((await _rows('applications')).isNotEmpty) throw StateError('Officers supply addresses for existing applications. Edit the officer instead.');
    }
    if (table == 'master_data') {
      final masters = await _rows('master_data');
      final entry = masters.where((r) => r['id'] == id).firstOrNull;
      if (entry != null) {
        final code = entry['code']?.toString() ?? '';
        final type = entry['masterType']?.toString() ?? '';
        if (masters.any((r) => r['id'] != id && (
          (type == 'Species' && r['masterType'] == 'Felling Exempted Species' && r['code'].toString() == id.toString()) ||
          (code.isNotEmpty && r['parentCode']?.toString() == code)))) {
          throw StateError('Entry has dependent master mappings. Remove those mappings or deactivate the entry.');
        }
      }
    }
    for (final entry in references.entries) {
      final used = (await _rows(entry.key)).any((row) => entry.value.any((field) {
        final value = row[field];
        if (value == id) return true;
        if (value is List) return value.contains(id);
        if (value is String && field.endsWith('Ids')) return RegExp(r'\d+').allMatches(value).any((m) => int.tryParse(m.group(0)!) == id);
        return false;
      }));
      if (used) throw StateError('Entry is already used by ${entry.key}. Deactivate it instead.');
    }
    if (OnlineMode.enabled) { await OnlineDatabase.delete(table, column: 'id', value: id); }
    else { await (await DatabaseHelper.instance.database).delete(table, where: 'id=?', whereArgs: [id]); }
  }
}
