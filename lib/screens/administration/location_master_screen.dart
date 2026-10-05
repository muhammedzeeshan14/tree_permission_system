import 'package:flutter/material.dart';
import '../../repositories/section_repository.dart';
import '../../repositories/beat_repository.dart';

class LocationMasterScreen extends StatefulWidget {
  const LocationMasterScreen({super.key, this.beats = false});
  final bool beats;
  @override
  State<LocationMasterScreen> createState() => _LocationMasterScreenState();
}

class _LocationMasterScreenState extends State<LocationMasterScreen> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  String? error;
  String get label => widget.beats ? 'Beat' : 'Section';
  String get nameKey => widget.beats ? 'beatName' : 'sectionName';
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { loading = true; error = null; });
    try {
      final rows = widget.beats ? await BeatRepository().getAll() : await SectionRepository().getAll();
      if (mounted) setState(() => items = rows);
    } catch (e) { if (mounted) setState(() => error = e.toString()); }
    finally { if (mounted) setState(() => loading = false); }
  }
  Future<void> _edit([Map<String, dynamic>? item]) async {
    List<Map<String, dynamic>> sections = [];
    try { if (widget.beats) sections = await SectionRepository().getAll(); }
    catch (e) { _message(e.toString()); return; }
    if (!mounted) return;
    final name = TextEditingController(text: item?[nameKey]?.toString() ?? '');
    final kannada = TextEditingController(text: item?['kannadaName']?.toString() ?? '');
    final order = TextEditingController(text: item?['displayOrder']?.toString() ?? '1');
    int? sectionId = (item?['sectionId'] as num?)?.toInt();
    var active = item?['isActive'] != 0;
    var saving = false;
    String? saveError;
    final form = GlobalKey<FormState>();
    final saved = await showDialog<bool>(context: context, barrierDismissible: false, builder: (dialogContext) => StatefulBuilder(builder: (context, update) => PopScope(
      canPop: !saving,
      child: AlertDialog(
        title: Text('${item == null ? 'Add' : 'Edit'} $label'),
        content: SizedBox(width: 420, child: SingleChildScrollView(child: Form(key: form, child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (widget.beats) DropdownButtonFormField<int>(
            initialValue: sections.any((s) => s['id'] == sectionId) ? sectionId : null,
            isExpanded: true, itemHeight: null,
            decoration: const InputDecoration(labelText: 'Section'),
            items: sections.where((s) => s['isActive'] == 1 || s['id'] == sectionId).map((s) => DropdownMenuItem<int>(value: (s['id'] as num).toInt(), child: Text(s['sectionName'].toString()))).toList(),
            onChanged: saving ? null : (value) => update(() => sectionId = value),
            validator: (value) => value == null ? 'Select a section. Add an active section first if none are available.' : null,
          ),
          TextFormField(controller: name, enabled: !saving, decoration: InputDecoration(labelText: '$label Name (English)'), validator: (v) => (v ?? '').trim().isEmpty ? 'Enter a name' : null),
          TextFormField(controller: kannada, enabled: !saving, decoration: InputDecoration(labelText: '$label Name (Kannada)')),
          TextFormField(controller: order, enabled: !saving, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Display Order'), validator: (v) => int.tryParse(v ?? '') == null ? 'Enter a whole number' : null),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Active'), value: active, onChanged: saving ? null : (v) => update(() => active = v)),
          if (saveError != null) Text(saveError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ])))),
        actions: [
          TextButton(onPressed: saving ? null : () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: saving ? null : () async {
            if (!form.currentState!.validate()) return;
            update(() { saving = true; saveError = null; });
            try {
              final id = (item?['id'] as num?)?.toInt();
              if (widget.beats) {
                if (id == null) { await BeatRepository().insert(sectionId: sectionId!, beatName: name.text, kannadaName: kannada.text.trim(), displayOrder: int.parse(order.text), isActive: active); }
                else { await BeatRepository().update(id: id, sectionId: sectionId!, beatName: name.text, kannadaName: kannada.text.trim(), displayOrder: int.parse(order.text), isActive: active); }
              } else {
                if (id == null) { await SectionRepository().insert(sectionName: name.text, kannadaName: kannada.text.trim(), displayOrder: int.parse(order.text), isActive: active); }
                else { await SectionRepository().update(id: id, sectionName: name.text, kannadaName: kannada.text.trim(), displayOrder: int.parse(order.text), isActive: active); }
              }
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            } catch (e) { if (dialogContext.mounted) update(() { saving = false; saveError = 'Could not save: $e'; }); }
          }, child: Text(saving ? 'Saving…' : 'Save')),
        ],
      ),
    )));
    // Wait until the closing dialog animation no longer uses its controllers.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    name.dispose(); kannada.dispose(); order.dispose();
    if (saved == true && mounted) { _message('$label saved'); await _load(); }
  }
  void _message(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
  Future<void> _delete(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(context: context, builder: (c) => AlertDialog(title: Text('Delete $label'), content: Text('Delete "${item[nameKey]}"? Entries already used by applications or users must be deactivated instead.'), actions: [TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')), FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete'))]));
    if (confirmed != true || !mounted) return;
    setState(() => loading = true);
    try {
      final id = (item['id'] as num).toInt();
      if (widget.beats) { await BeatRepository().delete(id); } else { await SectionRepository().delete(id); }
      _message('$label deleted');
    } catch (e) { _message('Cannot delete: $e'); }
    await _load();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('$label Master'), actions: [IconButton(tooltip: 'Refresh', onPressed: loading ? null : _load, icon: const Icon(Icons.refresh))]),
    floatingActionButton: FloatingActionButton.extended(onPressed: loading ? null : () => _edit(), icon: const Icon(Icons.add), label: Text('Add $label')),
    body: loading ? const Center(child: CircularProgressIndicator()) : error != null ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!), TextButton(onPressed: _load, child: const Text('Retry'))]))) : RefreshIndicator(onRefresh: _load, child: ListView(padding: const EdgeInsets.only(bottom: 100), physics: const AlwaysScrollableScrollPhysics(), children: [
      if (items.isEmpty) Padding(padding: const EdgeInsets.all(24), child: Text('No ${label.toLowerCase()}s yet. Use Add $label to create one.')),
      ...items.map((item) => ListTile(onTap: () => _edit(item), title: Text(item[nameKey]?.toString() ?? ''), subtitle: Text([item['kannadaName']?.toString() ?? '', if (widget.beats) item['sectionName']?.toString() ?? '', item['isActive'] == 1 ? 'Active' : 'Inactive'].where((s) => s.isNotEmpty).join(' • ')), trailing: PopupMenuButton<String>(tooltip: '$label actions', onSelected: (action) { if (action == 'edit') { _edit(item); } else { _delete(item); } }, itemBuilder: (_) => const [PopupMenuItem(value: 'edit', child: Text('Edit')), PopupMenuItem(value: 'delete', child: Text('Delete'))]))),
    ])),
  );
}
