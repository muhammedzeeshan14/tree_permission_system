/// Resolve labels only against the deferred-reason master, never another master
/// which happens to have the saved ID. English is for screens; Kannada Name is
/// the exact, user-entered document label (it need not contain Kannada script).
List<Map<String, dynamic>> resolveDeferredReasons(
  List<Map<String, dynamic>> saved,
  List<Map<String, dynamic>> masters,
) {
  final valid = masters
      .where((m) => m['masterType'] == 'Inspection Deferred Reason')
      .toList();
  final sorted = saved.map((r) => Map<String, dynamic>.from(r)).toList()
    ..sort(
      (a, b) => ((a['displayOrder'] as num?)?.toInt() ?? 0).compareTo(
        (b['displayOrder'] as num?)?.toInt() ?? 0,
      ),
    );
  return sorted.map((row) {
    final id = (row['reasonId'] as num?)?.toInt();
    final matches = valid.where((m) => m['id'] == id).toList();
    final master = matches.isEmpty ? null : matches.first;
    final name = master?['value']?.toString().trim() ?? '';
    return <String, dynamic>{
      ...row,
      'masterAvailable': master != null,
      'reasonName': name.isEmpty
          ? 'Deferred reason unavailable (ID $id). Please reselect.'
          : name,
      'documentReasonName': master?['kannadaName']?.toString().trim() ?? '',
    };
  }).toList();
}

String deferredReasonSummary(List<Map<String, dynamic>> reasons) =>
    reasons.isEmpty
    ? 'No deferred reasons selected.'
    : reasons.map((r) => '• ${r['reasonName']}').join('\n');

String deferredReasonDocumentText(
  List<Map<String, dynamic>> reasons, {
  bool commaSeparated = false,
}) {
  if (reasons.isEmpty) {
    throw StateError(
      'Select the inspection deferred reasons before generating the letter.',
    );
  }
  final names = <String>[];
  for (final reason in reasons) {
    if (reason['masterAvailable'] != true) {
      throw StateError(
        'A saved deferred reason is no longer valid. Please reselect the deferred reasons.',
      );
    }
    final name = reason['documentReasonName']?.toString().trim() ?? '';
    if (name.isEmpty) {
      throw StateError(
        'Fill the Kannada Name for deferred reason "${reason['reasonName']}" in Administration Masters.',
      );
    }
    names.add(name);
  }
  if (commaSeparated || names.length == 1) return names.join(', ');
  return '${names.take(names.length - 1).join(', ')} ಮತ್ತು ${names.last}';
}
