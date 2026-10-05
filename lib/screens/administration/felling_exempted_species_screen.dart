import '../../widgets/master_entry_actions.dart';
import '../../services/master_entry_deletion.dart';
import 'package:flutter/material.dart';
import '../../repositories/master_repository.dart';
import '../../services/felling_exemptions.dart';
import '../../services/session_service.dart';

class FellingExemptedSpeciesScreen extends StatefulWidget {
  const FellingExemptedSpeciesScreen({super.key});
  @override
  State<FellingExemptedSpeciesScreen> createState() =>
      _FellingExemptedSpeciesScreenState();
}

class _FellingExemptedSpeciesScreenState
    extends State<FellingExemptedSpeciesScreen> {
  static const masterType = 'Felling Exempted Species';
  final repository = MasterRepository();
  List<Map<String, dynamic>> species = [], mappings = [];
  bool loading = true;
  String? error;
  bool get canEdit =>
      SessionService.instance.role.trim().toUpperCase() == 'RFO';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    try {
      final all = await repository.getMasters('Species');
      final rows = await repository.getMasters(masterType);
      if (!mounted) return;
      setState(() {
        species = all.where((s) => s['isActive'] == 1).toList();
        mappings = rows;
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
    if (mounted) setState(() => loading = false);
  }

  Future<void> edit([Map<String, dynamic>? existing]) async {
    if (!canEdit) return;
    String? selected = existing?['code']?.toString();
    if (!species.any((s) => s['id'].toString() == selected)) selected = null;
    String? roles = existing?['parentCode']?.toString();
    if (!FellingExemptions.combinations.contains(roles)) roles = null;
    bool saving = false;
    String? message;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text(
            existing == null ? 'Add exempted species' : 'Edit exempted species',
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Species'),
                    items: species
                        .map(
                          (s) => DropdownMenuItem(
                            value: s['id'].toString(),
                            child: Text(
                              '${s['value']} (${s['speciesGroup'] ?? 'TIMBER'})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: saving
                        ? null
                        : (v) => update(() => selected = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: roles,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Exempted tree officers',
                    ),
                    items: FellingExemptions.combinations
                        .map(
                          (r) => DropdownMenuItem(
                            value: r,
                            child: Text(r.replaceAll(',', ', ')),
                          ),
                        )
                        .toList(),
                    onChanged: saving ? null : (v) => update(() => roles = v),
                  ),
                  if (message != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(message!),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (selected == null || roles == null) {
                        update(
                          () => message = 'Select a species and tree officers.',
                        );
                        return;
                      }
                      update(() {
                        saving = true;
                        message = null;
                      });
                      try {
                        final chosen = species.firstWhere(
                          (s) => s['id'].toString() == selected,
                        );
                        final current = await repository.getMasters(masterType);
                        final equivalentIds = species
                            .where(
                              (s) =>
                                  FellingExemptions.name(s['value']) ==
                                  FellingExemptions.name(chosen['value']),
                            )
                            .map((s) => s['id'].toString())
                            .toSet();
                        if (current.any(
                          (m) =>
                              m['id'] != existing?['id'] &&
                              equivalentIds.contains(m['code'].toString()),
                        )) {
                          throw StateError(
                            'This species already has a mapping. Edit that mapping instead.',
                          );
                        }
                        if (existing == null) {
                          await repository.insert(
                            masterType: masterType,
                            value: chosen['value'].toString(),
                            code: selected!,
                            displayOrder: current.length,
                            remarks: '',
                            isActive: true,
                            parentCode: roles!,
                          );
                        } else {
                          await repository.update(
                            id: (existing['id'] as num).toInt(),
                            value: chosen['value'].toString(),
                            code: selected!,
                            displayOrder:
                                (existing['displayOrder'] as num?)?.toInt() ??
                                0,
                            remarks: '',
                            isActive: true,
                            parentCode: roles!,
                          );
                        }
                        if (dialogContext.mounted) Navigator.pop(dialogContext);
                      } catch (e) {
                        if (dialogContext.mounted)
                          update(() {
                            saving = false;
                            message = e.toString();
                          });
                      }
                    },
              child: Text(saving ? 'Saving...' : 'Save mapping'),
            ),
          ],
        ),
      ),
    );
    await load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Felling Exempted Species')),
    floatingActionButton: canEdit && !loading && error == null
        ? FloatingActionButton.extended(
            onPressed: edit,
            icon: const Icon(Icons.add),
            label: const Text('Add mapping'),
          )
        : null,
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(child: Text(error!))
        : ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              const Text(
                'For PL applications only, these species are hidden during tree entry for the mapped tree officers.',
              ),
              if (mappings.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No exemptions mapped.'),
                ),
              for (final row in mappings)
                Card(
                  child: ListTile(
                    title: Text(
                      species
                              .where(
                                (s) =>
                                    s['id'].toString() ==
                                    row['code'].toString(),
                              )
                              .map((s) => s['value'].toString())
                              .firstOrNull ??
                          row['value'].toString(),
                    ),
                    subtitle: Text(
                      row['parentCode'].toString().replaceAll(',', ', '),
                    ),
                    trailing: canEdit
                        ? MasterEntryActions(name: row['value'].toString(), onEdit: () => edit(row), onDelete: () => MasterEntryDeletion.delete('master_data', (row['id'] as num).toInt()), onReload: load)
                        : null,
                  ),
                ),
            ],
          ),
  );
}
