import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/application_model.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/history_repository.dart';
import '../../repositories/office_configuration_repository.dart';
import '../../services/online_database.dart';
import '../../services/online_mode.dart';

const applicationSearchFields = ['All fields', 'Application number', 'Application type', 'Beat', 'Section', 'Applicant name'];

bool matchesApplication(ApplicationModel app, String field, String query) {
  final values = <String, String>{
    'Application number': app.officeNumber,
    'Application type': '${app.applicationType} ${app.verifiedApplicationType}',
    'Beat': app.beat, 'Section': app.section, 'Applicant name': app.applicantName,
  };
  final needle = query.trim().toLowerCase();
  return (field == 'All fields' ? values.values : [values[field] ?? ''])
      .any((value) => value.toLowerCase().contains(needle));
}

String applicationLocation(ApplicationModel app) {
  String officer(String role, String name, String area) =>
    [role, name, area].where((s) => s.trim().isNotEmpty).join(' — ');
  switch (app.status) {
    case 'Completed': return 'Completed';
    case 'Approved': return 'Caseworker — RFO Approved Print';
    case 'Pending Revenue Opinion': return 'Caseworker — Pending Revenue Opinion';
    case 'Pending Government land approvals': return 'Caseworker — Pending Government Land Approvals';
    case 'Pending RFO Approval': return 'RFO — Pending Approvals';
    case 'Draft':
    case 'Returned to Case Worker': return 'Caseworker';
    case 'Pending BFO Inspection':
    case 'Returned to BFO': return officer('BFO', app.assignedBFO, app.beat);
    case 'Pending DRFO Assignment':
    case 'Pending DRFO Self Inspection':
    case 'Pending DRFO Re-Self Inspection':
    case 'Pending DRFO Verification':
    case 'Returned to DRFO': return officer('DRFO', app.assignedDRFO, app.section);
    default: return app.status;
  }
}

class ApplicationSearchScreen extends StatefulWidget {
  const ApplicationSearchScreen({super.key});
  @override
  State<ApplicationSearchScreen> createState() => _ApplicationSearchScreenState();
}

class _ApplicationSearchScreenState extends State<ApplicationSearchScreen> {
  final _query = TextEditingController();
  String _field = 'All fields';
  List<ApplicationModel> _apps = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _query.dispose(); super.dispose(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final apps = await ApplicationRepository().getApplications(includeReferences: false);
      if (mounted) setState(() => _apps = apps);
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load applications. Please refresh to retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final matches = _apps.where((a) => matchesApplication(a, _field, _query.text)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('SEARCH'), actions: [IconButton(
        tooltip: 'Refresh applications', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))]),
      body: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          DropdownButtonFormField<String>(initialValue: _field, isExpanded: true,
            decoration: const InputDecoration(labelText: 'Search by', border: OutlineInputBorder()),
            items: applicationSearchFields.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) { if (v != null) setState(() => _field = v); }),
          const SizedBox(height: 12),
          TextField(controller: _query, onChanged: (_) => setState(() {}),
            decoration: InputDecoration(labelText: 'Enter search text', prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(), suffixIcon: IconButton(tooltip: 'Clear search',
                icon: const Icon(Icons.clear), onPressed: () { _query.clear(); setState(() {}); }))),
          const SizedBox(height: 8),
          Text('All applications, including completed • ${matches.length} results'),
        ])),
        Expanded(child: _loading ? const Center(child: CircularProgressIndicator())
          : _error != null ? Center(child: Text(_error!))
          : matches.isEmpty ? const Center(child: Text('No matching applications'))
          : ListView.builder(itemCount: matches.length, itemBuilder: (context, i) {
            final a = matches[i];
            return Card(margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: ListTile(
              title: Text(a.officeNumber),
              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${a.applicantName} • ${a.applicationType}'),
                Text('${a.section} • ${a.beat}'),
                Text(a.status == 'Completed' ? 'Completed' : '${a.status}\nWith: ${applicationLocation(a)}',
                  style: TextStyle(color: a.status == 'Completed' ? Colors.green.shade800 : null,
                    fontWeight: FontWeight.bold)),
              ]), trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => ApplicationStatusScreen(officeNumber: a.officeNumber))),
            ));
          })),
      ]),
    );
  }
}

class ApplicationStatusScreen extends StatefulWidget {
  final String officeNumber;
  const ApplicationStatusScreen({super.key, required this.officeNumber});
  @override
  State<ApplicationStatusScreen> createState() => _ApplicationStatusScreenState();
}

class _ApplicationStatusScreenState extends State<ApplicationStatusScreen> {
  ApplicationModel? _app;
  Map<String, dynamic>? _office;
  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait<dynamic>([
        ApplicationRepository().getByOfficeNumber(widget.officeNumber),
        OfficeConfigurationRepository().getConfiguration(),
        OnlineMode.enabled ? OnlineDatabase.selectAll('application_history',
          equals: {'officeNumber': widget.officeNumber}, orderBy: 'id')
          : HistoryRepository().getHistory(widget.officeNumber),
      ]);
      if (mounted) setState(() {
        _app = results[0] as ApplicationModel?;
        _office = results[1] as Map<String, dynamic>?;
        _history = results[2] as List<Map<String, dynamic>>;
        if (_app == null) { _error = 'Application no longer available.'; }
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load current file status. Please refresh to retry.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  String _date(dynamic value) {
    final raw = value?.toString() ?? '';
    final date = DateTime.tryParse(raw);
    return date == null ? (raw.isEmpty ? 'Not recorded' : raw) : DateFormat('dd-MM-yyyy HH:mm').format(date.toLocal());
  }
  Widget _detail(String label, String value) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
    child: Text.rich(TextSpan(children: [TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
      TextSpan(text: value.trim().isEmpty ? 'Not recorded' : value.replaceAll(RegExp(r'\s*\n\s*'), ', '))])));
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('File status report'), actions: [IconButton(
      tooltip: 'Refresh status', onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh))]),
    body: _loading ? const Center(child: CircularProgressIndicator())
      : _error != null ? Center(child: Text(_error!)) : _report(_app!),
  );
  Widget _report(ApplicationModel a) => SingleChildScrollView(padding: const EdgeInsets.all(16),
    child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 900),
      child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text([if ((_office?['rangeName'] ?? '').toString().isNotEmpty) '${_office!['rangeName']} Range',
            if ((_office?['rangeLocation'] ?? '').toString().isNotEmpty) '${_office!['rangeLocation']}'].join(', '),
            textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          const Text('File status report', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(),
          _detail('File No.', a.officeNumber), _detail('Application type', a.applicationType),
          _detail('Applicant name', a.applicantName), _detail('Address', a.applicantAddress),
          _detail('Section', a.section), _detail('Beat', a.beat),
          const Divider(),
          _detail('Current stage', a.status), _detail('Currently with', applicationLocation(a)),
          const SizedBox(height: 16),
          const Text('Recorded action history', style: TextStyle(fontWeight: FontWeight.bold)),
          if (_history.isEmpty) const Padding(padding: EdgeInsets.all(12), child: Text('No recorded actions are available for this file.')),
          for (var i = 0; i < _history.length; i++) Container(
            padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(6)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Stage ${i + 1} • ${_date(_history[i]['actionDate'])}', style: const TextStyle(fontWeight: FontWeight.bold)),
              _detail('Action taken', _history[i]['action']?.toString() ?? ''),
              _detail('Action by', _history[i]['actionBy']?.toString() ?? ''),
            ])),
          const SizedBox(height: 16),
          Text(a.status == 'Completed' ? 'Completed' : '${a.status} — ${applicationLocation(a)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,
              color: a.status == 'Completed' ? Colors.green.shade800 : null)),
        ])),
      ),
    )),
  );
}
