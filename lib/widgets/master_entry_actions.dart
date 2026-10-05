import 'package:flutter/material.dart';

class MasterEntryActions extends StatelessWidget {
  const MasterEntryActions({super.key, required this.name, required this.onEdit, required this.onDelete, required this.onReload});
  final String name;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;
  final Future<void> Function() onReload;
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Edit or delete',
    itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))],
    onSelected: (action) async {
      if (action == 'edit') { onEdit(); return; }
      final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: const Text('Delete entry'), content: Text('Delete "$name"? Entries used by applications must be deactivated instead.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))]));
      if (confirmed != true) return;
      try { await onDelete(); await onReload(); }
      catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot delete: $e'))); }
    },
  );
}
