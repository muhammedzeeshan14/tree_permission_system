import 'package:flutter/material.dart';

/// Owns the controller until the dialog's closing animation has finished.
class TreeCountSpeciesDialog extends StatefulWidget {
  final List<Map<String, dynamic>> species;
  const TreeCountSpeciesDialog({super.key, required this.species});

  @override
  State<TreeCountSpeciesDialog> createState() => _TreeCountSpeciesDialogState();
}

class _TreeCountSpeciesDialogState extends State<TreeCountSpeciesDialog> {
  final controller = TextEditingController();
  String query = '';

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.species.where((s) =>
        (s['value']?.toString() ?? '').toLowerCase().contains(query)).toList();
    return AlertDialog(
      title: const Text('Select Species'),
      content: SizedBox(width: 450, height: 500, child: Column(children: [
        TextField(controller: controller, autofocus: true,
          decoration: const InputDecoration(labelText: 'Search Species',
            hintText: 'Type species name', prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder()),
          onChanged: (value) => setState(() => query = value.trim().toLowerCase())),
        const SizedBox(height: 12),
        Expanded(child: filtered.isEmpty ? const Center(child: Text('No species found'))
          : ListView.builder(itemCount: filtered.length, itemBuilder: (context, index) {
            final species = filtered[index];
            return ListTile(title: Text(species['value']?.toString() ?? ''),
              subtitle: Text(species['speciesGroup']?.toString() ?? ''),
              onTap: () => Navigator.pop(context, species));
          })),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL'))],
    );
  }
}
