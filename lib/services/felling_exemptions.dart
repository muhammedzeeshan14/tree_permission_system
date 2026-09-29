/// Officer mappings use exact role tokens, never substring matching.
class FellingExemptions {
  static const combinations = [
    'RFO',
    'ACF',
    'DCF',
    'RFO,ACF,DCF',
    'RFO,ACF',
    'RFO,DCF',
    'ACF,DCF',
  ];
  static String name(Object? value) =>
      (value ?? '').toString().trim().toLowerCase();
  static Set<String> excludedIds(
    List<Map<String, dynamic>> mappings,
    List<Map<String, dynamic>> species,
    String officer,
  ) {
    final ids = <String>{};
    final names = <String>{};
    for (final mapping in mappings) {
      if (mapping['isActive'] != 1 ||
          !mapping['parentCode'].toString().split(',').contains(officer))
        continue;
      final id = mapping['code'].toString();
      ids.add(id);
      final matches = species.where((s) => s['id'].toString() == id);
      if (matches.isNotEmpty) names.add(name(matches.first['value']));
    }
    // TIMBER and POLE records of the same species share the exemption.
    for (final row in species) {
      if (names.contains(name(row['value']))) ids.add(row['id'].toString());
    }
    return ids;
  }
}
