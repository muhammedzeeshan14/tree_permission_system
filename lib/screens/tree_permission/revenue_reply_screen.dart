import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/application_model.dart';
import '../../models/revenue_reply_model.dart';
import '../../models/revenue_opinion_model.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/revenue_reply_repository.dart';
import '../../repositories/revenue_opinion_repository.dart';
import '../../repositories/tree_officer_repository.dart';
import '../../repositories/officer_repository.dart';
import '../../services/drfo_document_service.dart';
import '../../services/session_service.dart';
import '../../constants/workflow_status.dart';
import '../bfo/wizard/inspection_summary_step.dart';

String revenueDate(String value) {
  final date = DateTime.tryParse(value);
  return date == null
      ? value.replaceAll('/', '-')
      : '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
}

class PendingRevenueOpinionScreen extends StatefulWidget {
  const PendingRevenueOpinionScreen({super.key});
  @override
  State<PendingRevenueOpinionScreen> createState() =>
      _PendingRevenueOpinionScreenState();
}

class _PendingRevenueOpinionScreenState
    extends State<PendingRevenueOpinionScreen> {
  late Future<List<ApplicationModel>> applications;
  @override
  void initState() {
    super.initState();
    applications = _load();
  }

  Future<List<ApplicationModel>> _load() async {
    final all = await ApplicationRepository().getApplications();
    final result = <ApplicationModel>[];
    for (final app in all) {
      if (app.createdBy != SessionService.instance.userId) continue;
      final current =
          await RevenueReplyRepository().current(app.id!);
      if (app.status == WorkflowStatus.pendingRevenueOpinion &&
          current?.stage == 'pending') {
        result.add(app);
        continue;
      }
      // Completed but applicant never applied online: stay visible
      // so the caseworker can reopen and enter the number later.
      if (app.status == WorkflowStatus.completed &&
          current?.stage == 'completed' &&
          current!.answers['onlineApplicationStatus'] ==
              RevenueReply.onlineNotApplied &&
          (current.answers['onlineApplicationNumber'] ?? '')
              .trim()
              .isEmpty) {
        result.add(app);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pending Revenue Opinion')),
    body: FutureBuilder<List<ApplicationModel>>(
      future: applications,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load applications: ${snapshot.error}',
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(
            child: Text('No applications awaiting revenue opinion.'),
          );
        }
        return ListView(
          children: snapshot.data!
              .map(
                (app) => Card(
                  child: ListTile(
                    title: Text(app.officeNumber),
                    subtitle: Text(app.applicantName),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              RevenueReplyWorkflowScreen(application: app),
                        ),
                      );
                      if (mounted) setState(() => applications = _load());
                    },
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}

class RevenueReplyWorkflowScreen extends StatefulWidget {
  final ApplicationModel application;
  final bool rfo;
  const RevenueReplyWorkflowScreen({
    super.key,
    required this.application,
    this.rfo = false,
  });
  @override
  State<RevenueReplyWorkflowScreen> createState() =>
      _RevenueReplyWorkflowScreenState();
}

class _RevenueReplyWorkflowScreenState
    extends State<RevenueReplyWorkflowScreen> {
  final repository = RevenueReplyRepository();
  RevenueReply? reply;
  List<RevenueOpinionModel> authorities = [];
  List<Map<String, dynamic>> treeOfficers = [];
  Map<String, String> officerDisplayNames = {};
  int? selectedTreeOfficerId;

  bool get isSandal =>
      widget.application.applicationType.trim().toUpperCase() ==
      'SPL';
  int step = 0;
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final current = await repository.current(widget.application.id!);
      final options = widget.rfo
          ? await RevenueOpinionRepository().getActive()
          : <RevenueOpinionModel>[];
      final officers = widget.rfo ? await TreeOfficerRepository().getAll() : <Map<String, dynamic>>[];
      final officerId = widget.rfo ? await TreeOfficerRepository().getSelection(widget.application.id!) : null;
      // Display names come from the officer master; the tree-officer
      // mapping only carries the felling-permission flag.
      final displayNames = <String, String>{};
      if (widget.rfo) {
        try {
          final directory = await OfficerRepository().getAll();
          for (final entry in directory) {
            final role = (entry['role']?.toString() ?? '').trim().toUpperCase();
            final name = (entry['name']?.toString() ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
            if (role.isNotEmpty && name.isNotEmpty) displayNames[role] = name;
          }
        } catch (_) {
          // Fall back to mapping names below.
        }
      }
      if (!mounted) return;
      setState(() {
        treeOfficers = officers;
        officerDisplayNames = displayNames;
        selectedTreeOfficerId = officerId;
        reply = current;
        authorities = options;
        if (current == null) error = 'Revenue request was not found.';
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _edit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RevenueReplyEntryScreen(
            reply: reply!,
            rfo: widget.rfo,
            applicationType:
                widget.application.applicationType),
      ),
    );
    if (!mounted) return;
    if (result == true && !widget.rfo) {
      Navigator.pop(context, true);
      return;
    }
    await _load();
  }

  Future<void> _finalize() async {
    final current = reply!;
    if (!current.allApprovedFor(includeOnline: !isSandal)) {
      throw StateError('Approve every answer first.');
    }
    final now = DateTime.now().toIso8601String();
    final previousDate = widget.application.rfoApprovalDate;
    widget.application.rfoApprovalDate = now;
    try {
      final documents = DrfoDocumentService();
      final File? file;
      if (current.answers['nature'] == RevenueReply.wrongAuthority) {
        if (current.nextAuthorityId == null) {
          throw StateError('Select the new revenue opinion giving authority.');
        }
        file = await documents.generateRfoRevenueOpinionRequestLetter(
          widget.application,
          authorityId: current.nextAuthorityId,
          requestCycle: current.cycle + 1,
        );
      } else {
        // Sandal Private: To is always the DCF officer; no tree-officer
        // outcome or selection is needed.
        final isSandal = widget.application.applicationType
                .trim()
                .toUpperCase() ==
            'SPL';
        // Single letter per outcome (never multiple):
        // - felling required (tree-officer outcome) + online NOT
        //   applied -> ONLY the apply-online letter; the case stays
        //   open until the caseworker refills the online number.
        // - all other satisfied cases -> the normal decision letter.
        final holdingForOnlineNumber = !isSandal &&
            current.answers['nature'] ==
                RevenueReply.satisfied &&
            current.answers['onlineApplicationStatus'] ==
                RevenueReply.onlineNotApplied &&
            (await TreeOfficerRepository().getCompletionOutcome(
                    widget.application.id!)) ==
                PrivateLandOutcome.treeOfficerLetter;
        if (holdingForOnlineNumber) {
          file = await documents.generateRfoApplyOnlineLetter(
            widget.application,
            current,
          );
        } else if (isSandal &&
            current.answers['nature'] ==
                RevenueReply.satisfied) {
          file = await documents.generateRfoSandalApprovalLetter(
            widget.application,
            current,
          );
        } else {
          file = await documents.generateRfoPrivateLandDecisionLetter(
            widget.application,
            current,
          );
        }
      }
      await repository.finalize(
        current,
        file?.path ?? '',
        now,
        outcomeOverride: widget.application.applicationType
                    .trim()
                    .toUpperCase() ==
                'SPL'
            ? PrivateLandOutcome.treeOfficerLetter
            : null,
        includeOnline: !isSandal,
      );
      widget.application.status =
          current.answers['nature'] == RevenueReply.wrongAuthority
          ? WorkflowStatus.pendingRevenueOpinion
          : WorkflowStatus.completed;
      if (mounted && file == null) {
        await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
          title: const Text('Application completed'),
          content: const Text('Give online permission in Aranya website.'),
          actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('OK'))],
        ));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      widget.application.rfoApprovalDate = previousDate;
      rethrow;
    }
  }

  Widget _review() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      const Text(
        'Approve Revenue Opinion',
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
      const Text(
        'Every answer must be approved. Re-inspect leaves the application unapproved. Modified answers must be reviewed again.',
      ),
      const SizedBox(height: 12),
      for (final field in RevenueReply.fields(reply!.answers,
          includeOnline: !isSandal))
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        RevenueReply.questions[field]!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 3,
                      child: SelectableText(
                        field.endsWith('Date')
                            ? revenueDate(reply!.answers[field] ?? '')
                            : (reply!.answers[field]?.isNotEmpty == true
                                  ? reply!.answers[field]!
                                  : '—'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final decision in [
                        'Approve',
                        'Modify',
                        'Re-inspect',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              backgroundColor:
                                  reply!.decisions[field] == decision
                                  ? (decision == 'Approve'
                                        ? Colors.green.shade100
                                        : Colors.orange.shade100)
                                  : null,
                            ),
                            onPressed: busy
                                ? null
                                : () => _run(() async {
                                    if (decision == 'Modify') {
                                      await _edit();
                                    } else {
                                      reply = await repository.decide(
                                        reply!,
                                        field,
                                        decision,
                                        includeOnline:
                                            !isSandal,
                                      );
                                    }
                                  }),
                            child: Text(decision),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
    ],
  );
  String get _satisfiedOutcomeMessage {
    if (isSandal) {
      return 'Final Approval generates the RFO sandal approval letter addressed to the DCF officer and completes the application.';
    }
    final selected = treeOfficers.where((row) => row['id'] == selectedTreeOfficerId);
    if (selected.isEmpty) return 'Select Tree officer to determine the final approval action.';
    try {
      switch (TreeOfficerRepository.outcomeFor(selected.first)) {
        case PrivateLandOutcome.onlinePermission:
          return 'Give online permission in Aranya website. Final Approval completes the application without generating a letter.';
        case PrivateLandOutcome.applicantLetter:
          return 'Final Approval generates the RFO PL approval applicant letter and completes the application.';
        case PrivateLandOutcome.treeOfficerLetter:
          if (reply?.answers['onlineApplicationStatus'] ==
              RevenueReply.onlineNotApplied) {
            return 'Online application is not applied. Final Approval generates only the apply-online letter; the case stays open until the online number is entered.';
          }
          return 'Final Approval generates the RFO PL approval letter addressed to the selected Tree Officer and completes the application.';
      }
    } catch (e) { return e.toString().replaceFirst('Bad state: ', ''); }
  }

  Widget _final() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Final Approval',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 18),
      Text(
        '${reply!.answers['nature'] ?? ''} Revenue Opinion',
        style: const TextStyle(fontSize: 20),
      ),
      const SizedBox(height: 18),
      if (reply!.answers['nature'] == RevenueReply.satisfied &&
          widget.application.applicationType
                  .trim()
                  .toUpperCase() !=
              'SPL') ...[
        DropdownButtonFormField<int>(
          initialValue: selectedTreeOfficerId,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Select Tree officer', border: OutlineInputBorder()),
          items: treeOfficers.map((row) {
            final code = (row['code']?.toString() ?? '').trim().toUpperCase();
            final label = officerDisplayNames[code] ??
                (row['name']?.toString() ?? code);
            return DropdownMenuItem<int>(
                value: row['id'] as int, child: Text('$label ($code)'));
          }).toList(),
          onChanged: busy ? null : (id) {
            if (id != null) {
              _run(() async {
              await TreeOfficerRepository().saveSelection(widget.application.id!, id);
              selectedTreeOfficerId = id;
            });
            }
          },
        ),
        const SizedBox(height: 18),
      ],
      if (reply!.answers['nature'] == RevenueReply.wrongAuthority) ...[
        const Text('Revenue opinion entry details'),
        const SizedBox(height: 12),
        DropdownButtonFormField<int>(
          initialValue: authorities.any((a) => a.id == reply!.nextAuthorityId)
              ? reply!.nextAuthorityId
              : null,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Revenue opinion giving authority',
            border: OutlineInputBorder(),
          ),
          items: authorities
              .map(
                (a) => DropdownMenuItem(
                  value: a.id,
                  child: Text('${a.officeName} — ${a.officeAddress}'),
                ),
              )
              .toList(),
          onChanged: busy
              ? null
              : (id) {
                  if (id != null) {
                    _run(() async {
                      reply = await repository.saveAuthority(reply!, id);
                    });
                  }
                },
        ),
        const SizedBox(height: 12),
        const Text(
          'Final approval generates a new request dated today and returns the case to the caseworker for printing.',
        ),
      ] else
        Text(
          reply!.answers['nature'] == RevenueReply.satisfied
              ? _satisfiedOutcomeMessage
              : 'Final approval generates the RFO private land rejection letter and completes the application.',
        ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Revenue Opinion')),
        body: Center(child: Text(error!)),
      );
    }
    if (reply == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return PopScope(
      canPop: !busy,
      child: Scaffold(
        appBar: AppBar(
          title: Text('${widget.application.officeNumber} — Revenue Opinion'),
        ),
        body: Column(
          children: [
            Expanded(
              child: step == 0
                  ? InspectionSummaryStep(
                      key: ValueKey(reply!.revision),
                      application: widget.application,
                      showNavigationButtons: false,
                      onBack: () {},
                      onNext: () {},
                    )
                  : step == 1
                  ? _review()
                  : _final(),
            ),
            if (busy) const LinearProgressIndicator(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: busy
                        ? null
                        : () {
                            if (step > 0) {
                              setState(() => step--);
                            } else {
                              Navigator.pop(context);
                            }
                          },
                    child: const Text('Back'),
                  ),
                  const Spacer(),
                  if (widget.rfo && step > 0)
                    OutlinedButton(
                      onPressed: busy ? null : () => Navigator.pop(context),
                      child: const Text('Save Draft'),
                    ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed:
                        busy || (widget.rfo && step == 1 && !reply!.allApprovedFor(includeOnline: !isSandal))
                        ? null
                        : () => _run(() async {
                            if (!widget.rfo) {
                              await _edit();
                            } else if (step < 2) {
                              setState(() => step++);
                            } else {
                              await _finalize();
                            }
                          }),
                    child: Text(
                      !widget.rfo
                          ? 'Enter revenue opinion details'
                          : step == 2
                          ? 'Final Approval'
                          : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RevenueReplyEntryScreen extends StatefulWidget {
  final RevenueReply reply;
  final bool rfo;
  final String applicationType;
  const RevenueReplyEntryScreen({
    super.key,
    required this.reply,
    this.rfo = false,
    this.applicationType = '',
  });
  @override
  State<RevenueReplyEntryScreen> createState() =>
      _RevenueReplyEntryScreenState();
}

class _RevenueReplyEntryScreenState extends State<RevenueReplyEntryScreen> {
  final repository = RevenueReplyRepository();
  late RevenueReply reply;
  late Map<String, TextEditingController> controllers;
  bool busy = false, allowPop = false;
  String saveStatus = '';
  Timer? debounce;
  Future<void> queue = Future.value();
  @override
  void initState() {
    super.initState();
    reply = widget.reply;
    controllers = {
      for (final field in RevenueReply.questions.keys)
        field: TextEditingController(text: reply.answers[field] ?? ''),
    };
  }

  Map<String, String> get answers => {
    for (final entry in controllers.entries) entry.key: entry.value.text,
  };

  bool get isSandal =>
      widget.applicationType.trim().toUpperCase() == 'SPL';
  void _changed() {
    setState(() {});
    if (!widget.rfo) return;
    debounce?.cancel();
    setState(() => saveStatus = 'Saving changes…');
    debounce = Timer(const Duration(milliseconds: 500), () {
      _autosave().catchError((Object _) {});
    });
  }

  Future<void> _autosave() {
    final values = answers;
    final operation = queue.then((_) async {
      reply = await repository.saveAnswers(reply, values,
          rfo: true, includeOnline: !isSandal);
      if (mounted) {
        setState(() => saveStatus = 'Changes saved. Review the answers again.');
      }
    });
    queue = operation.catchError((Object e) {
      if (mounted) setState(() => saveStatus = 'Save failed: $e');
    });
    return operation;
  }

  Future<void> _save({bool submit = false}) async {
    if (busy) return;
    setState(() => busy = true);
    debounce?.cancel();
    try {
      if (widget.rfo) {
        await queue;
        await _autosave();
      } else {
        reply = await repository.saveAnswers(reply, answers,
            submit: submit, includeOnline: !isSandal);
      }
      if (!mounted) return;
      setState(() => allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context, submit ? true : reply);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _date(String field) async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          DateTime.tryParse(controllers[field]!.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) {
      controllers[field]!.text = selected.toIso8601String().split('T').first;
      _changed();
    }
  }

  Widget _answer(String field) {
    if (field == 'nature') {
      return DropdownButtonFormField<String>(
        initialValue: RevenueReply.natures.contains(controllers[field]!.text)
            ? controllers[field]!.text
            : null,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        items: RevenueReply.natures
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: busy
            ? null
            : (value) {
                controllers[field]!.text = value ?? '';
                _changed();
              },
      );
    }
    if (field == 'onlineApplicationStatus') {
      return DropdownButtonFormField<String>(
        initialValue: RevenueReply.onlineStatuses
                .contains(controllers[field]!.text)
            ? controllers[field]!.text
            : null,
        decoration: const InputDecoration(border: OutlineInputBorder()),
        items: RevenueReply.onlineStatuses
            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
            .toList(),
        onChanged: busy
            ? null
            : (value) {
                controllers[field]!.text = value ?? '';
                if (value != RevenueReply.onlineApplied) {
                  controllers['onlineApplicationNumber']!.text = '';
                }
                _changed();
              },
      );
    }
    if (field.endsWith('Date')) {
      return OutlinedButton.icon(
        onPressed: busy ? null : () => _date(field),
        icon: const Icon(Icons.calendar_today),
        label: Text(
          controllers[field]!.text.isEmpty
              ? 'Select date'
              : revenueDate(controllers[field]!.text),
        ),
      );
    }
    return TextField(
      controller: controllers[field],
      enabled: !busy,
      minLines: 1,
      maxLines: 5,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      onChanged: (_) => _changed(),
    );
  }

  @override
  void dispose() {
    debounce?.cancel();
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: allowPop || (!widget.rfo && !busy),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop && widget.rfo && !busy) _save();
    },
    child: Scaffold(
      appBar: AppBar(title: const Text('Enter revenue opinion details')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final field in RevenueReply.fields(answers,
                    includeOnline: !isSandal))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              RevenueReply.questions[field]!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(flex: 3, child: _answer(field)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (saveStatus.isNotEmpty)
            Padding(padding: const EdgeInsets.all(8), child: Text(saveStatus)),
          if (busy) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: busy ? null : () => _save(),
                  child: Text(widget.rfo ? 'Done' : 'Save Draft'),
                ),
                if (!widget.rfo) ...[
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: busy ? null : () => _save(submit: true),
                    child: const Text('Send for RFO Approval'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
