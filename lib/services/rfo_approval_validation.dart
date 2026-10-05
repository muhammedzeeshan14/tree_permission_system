class RfoApprovalValidation {
  static String? error(Iterable<String> keys, Map<String, String?> decisions,
      Map<String, String?> reasons) {
    for (final key in keys) {
      final label = key.replaceAll('_', ' ');
      final choice = decisions[key];
      if (!const ['Approve', 'Modify', 'Re-inspect'].contains(choice)) {
        return 'Select Approve, Modify or Re-inspect for $label before Next.';
      }
      if (choice == 'Re-inspect' && (reasons[key]?.trim().isEmpty ?? true)) {
        return 'Select a re-inspection reason for $label before Next.';
      }
    }
    return null;
  }
}
