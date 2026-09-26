import 'package:flutter/material.dart';

import '../../repositories/master_repository.dart';

/// RFO masters: "Send sandal to" destinations with Kannada names,
/// mapped to Sandal Private (SPL), Sandal Government (SGL) or both.
class SandalDestinationMasterScreen extends StatefulWidget {
  const SandalDestinationMasterScreen({super.key});

  @override
  State<SandalDestinationMasterScreen> createState() =>
      _SandalDestinationMasterScreenState();
}

class _SandalDestinationMasterScreenState
    extends State<SandalDestinationMasterScreen> {
  static const String masterType = 'Sandal Destination';

  static const Map<String, String> mappings = {
    'SPL': 'Private Sandal (SPL)',
    'SGL': 'Government Sandal (SGL)',
    'BOTH': 'Both',
  };

  List<Map<String, dynamic>> items = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() => loading = true);
    items = await MasterRepository().getMasters(masterType);
    if (mounted) setState(() => loading = false);
  }

  String mappingLabel(String? parentCode) {
    final code =
        (parentCode ?? '').trim().toUpperCase();
    if (code.isEmpty) return 'Both';
    return mappings[code] ?? parentCode!;
  }

  Future<void> showDialog_({Map<String, dynamic>? item}) async {
    final valueController = TextEditingController(
      text: item?['value']?.toString() ?? '',
    );
    final kannadaController = TextEditingController(
      text: item?['kannadaName']?.toString() ?? '',
    );
    String mapping =
        (item?['parentCode']?.toString() ?? '').trim().toUpperCase();
    if (!mappings.containsKey(mapping)) mapping = 'BOTH';
    final displayOrderController = TextEditingController(
      text: item?['displayOrder']?.toString() ?? '1',
    );
    bool isActive = (item?['isActive'] ?? 1) == 1;

    await showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(item == null
              ? 'Add Sandal Destination'
              : 'Edit Sandal Destination'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: valueController,
                    decoration: const InputDecoration(
                      labelText: 'Destination Name (English)',
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: kannadaController,
                    decoration: const InputDecoration(
                      labelText: 'Destination Name (Kannada)',
                      hintText: 'ಶ್ರೀಗಂಧ ಡಿಪೋ',
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    initialValue: mapping,
                    decoration: const InputDecoration(
                      labelText: 'Applies To',
                      border: OutlineInputBorder(),
                    ),
                    items: mappings.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setDialogState(() => mapping = v);
                    },
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: displayOrderController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Display Order',
                    ),
                  ),
                  const SizedBox(height: 15),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) =>
                        setDialogState(() => isActive = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (valueController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Enter destination name.'),
                    ),
                  );
                  return;
                }
                try {
                  if (item == null) {
                    await MasterRepository().insert(
                      masterType: masterType,
                      value: valueController.text.trim(),
                      code: valueController.text
                          .trim()
                          .toUpperCase()
                          .replaceAll(RegExp(r'[^A-Z0-9]+'), '_'),
                      parentCode: mapping,
                      kannadaName:
                          kannadaController.text.trim(),
                      displayOrder: int.tryParse(
                              displayOrderController.text) ??
                          1,
                      remarks: '',
                      isActive: isActive,
                    );
                  } else {
                    await MasterRepository().update(
                      id: item['id'] as int,
                      value: valueController.text.trim(),
                      code: (item['code']?.toString() ??
                              '')
                          .trim()
                          .isNotEmpty
                          ? item['code'].toString()
                          : valueController.text
                              .trim()
                              .toUpperCase()
                              .replaceAll(
                                  RegExp(r'[^A-Z0-9]+'),
                                  '_'),
                      parentCode: mapping,
                      kannadaName:
                          kannadaController.text.trim(),
                      displayOrder: int.tryParse(
                              displayOrderController.text) ??
                          1,
                      remarks:
                          item['remarks']?.toString() ??
                              '',
                      isActive: isActive,
                    );
                  }
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                  await load();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      SnackBar(content: Text('$e')),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sandal Destinations'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : items.isEmpty
              ? const Center(
                  child: Text('No Records Found'),
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final kannada =
                        item['kannadaName']?.toString() ??
                            '';
                    return Card(
                      margin:
                          const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${index + 1}'),
                        ),
                        title: Text(
                          item['value']?.toString() ??
                              '',
                        ),
                        subtitle: Text(
                          [
                            if (kannada.trim().isNotEmpty)
                              kannada,
                            mappingLabel(item['parentCode']
                                ?.toString()),
                            (item['isActive'] == 1)
                                ? 'Active'
                                : 'Inactive',
                          ].join(' • '),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.edit),
                              onPressed: () =>
                                  showDialog_(
                                      item: item),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                final confirm =
                                    await showDialog<
                                        bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text(
                                        'Delete Destination'),
                                    content: Text(
                                      'Delete "${item['value']}"?',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                context,
                                                false),
                                        child: const Text(
                                            'Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(
                                                context,
                                                true),
                                        child: const Text(
                                            'Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await MasterRepository()
                                      .delete(
                                          item['id']
                                              as int);
                                  await load();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showDialog_(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
