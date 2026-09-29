import 'package:tree_permission_system/widgets/adaptive_layout.dart';
import '../../widgets/application_refresh_button.dart';
import '../../widgets/workflow_action.dart';
import 'revenue_reply_screen.dart';
import 'government_approval_screen.dart';
import '../../repositories/government_approval_repository.dart';
import '../../repositories/revenue_reply_repository.dart';
import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../repositories/application_repository.dart';
import '../../repositories/history_repository.dart';
import '../../repositories/master_repository.dart';
import '../../services/session_service.dart';
import 'new_application_screen.dart';
import '../rfo/rfo_decision_screen.dart';
import '../../constants/workflow_status.dart';

class ApplicationDetailsScreen extends StatefulWidget {
  final ApplicationModel application;

const ApplicationDetailsScreen({
  super.key,
  required this.application,
});

@override
State<ApplicationDetailsScreen> createState() =>
    _ApplicationDetailsScreenState();
}

class _ApplicationDetailsScreenState
    extends State<ApplicationDetailsScreen> {
late ApplicationModel _application;
Future<void> _refreshApplication() async {
  final latest = await ApplicationRepository().getById(_application.id!);
  if (!mounted) return;
  if (latest == null) throw StateError('Application no longer available.');
  _application = latest;
  await Future.wait([loadHistory(), loadAdditionalApplicationDetails()]);
  if (mounted) setState(() {});
}


List<Map<String,dynamic>> history=[];
final session = SessionService.instance;

String governmentAgencyName = "";
String urbanRuralName = "";
String structureTypeName = "";

bool get isGovernmentCategory {
  final type =
      _application.applicationType.trim().toUpperCase();

  return type == "GL" ||
      type == "STGL" ||
      type == "CGL" ||
      type == "SGL" ||
      type == "MCC";
}

bool get isMcc {
  return _application.applicationType
          .trim()
          .toUpperCase() ==
      "MCC";
}

bool get isPrivateCategory {
  final type =
      _application.applicationType.trim().toUpperCase();

  return type == "PL" || type == "SPL";
}

bool get showsAdditionalWorkDetails =>
    isGovernmentCategory || isPrivateCategory;

bool get isCaseWorker => session.role == "Case Worker";

bool get isDRFO => session.role == "DRFO";

bool get isBFO => session.role == "BFO";

bool get isRFO => session.role == "RFO";

@override
void initState(){

  super.initState();
  _application = widget.application;

  loadHistory();
  loadAdditionalApplicationDetails();

}

Future<void> loadHistory() async{

  history=await HistoryRepository().getHistory(
      _application.officeNumber);

  if (mounted) setState((){});

}

Future<void> loadAdditionalApplicationDetails() async {
  final repository = MasterRepository();

  final governmentAgency =
      await repository.getMasterById(
    _application.governmentAgencyId,
  );

  final urbanRural =
      await repository.getMasterById(
    _application.urbanRuralId,
  );

  final structureType =
      await repository.getMasterById(
    _application.structureTypeId,
  );

   String displayName(
    Map<String, dynamic>? item,
  ) {
    if (item == null) return "";

    return item["value"]?.toString().trim() ?? "";
  }

  governmentAgencyName =
      displayName(governmentAgency);

  urbanRuralName =
      displayName(urbanRural);

  structureTypeName =
      displayName(structureType);

  if (mounted) {
    setState(() {});
  }
}

  Widget detail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: AdaptiveRow(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: [ApplicationRefreshButton(onRefresh: _refreshApplication)],
        title: const Text("Application Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                detail("Office Number", _application.officeNumber),
                detail("Application Type", _application.applicationType),
                detail("Date of Application", _application.applicationDate),
                detail("Date Received", _application.receivedDate),
                detail("Applicant Name", _application.applicantName),
                detail("Address", _application.applicantAddress),
                detail("Mobile", _application.mobile),
                detail("Section", _application.section),
                detail("Beat", _application.beat),
                detail("Assigned BFO", _application.assignedBFO),
                detail("Assigned DRFO", _application.assignedDRFO),
                detail(
  "Purpose",
  _application.purpose,
),

if (isGovernmentCategory && !isMcc)
  detail(
    "Government Agency",
    governmentAgencyName,
  ),

if (isPrivateCategory)
  detail(
    "Urban / Rural",
    urbanRuralName,
  ),

if (showsAdditionalWorkDetails)
  detail(
    "Structure Type",
    structureTypeName,
  ),

if (showsAdditionalWorkDetails)
  detail(
    "Name of Work",
    _application.workName,
  ),

detail(
  "Status",
  _application.status,
),

                const Divider(),

const SizedBox(height: 20),

const Text(
  "Application History",
  style: TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 10),

history.isEmpty
    ? const Text("No history available.")
    : ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: history.length,
        itemBuilder: (context, index) {

          final item = history[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green,
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
              title: Text(
                item["action"] ?? "",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [

                  Text(
                      "Officer : ${item["actionBy"]}"),

                  Text(
                      "Remarks : ${item["remarks"]}"),

                  Text(
                      "Date : ${item["actionDate"]}"),
                ],
              ),
            ),
          );
        },
      ),
           const SizedBox(height: 30),

// ===============================
// CASE WORKER
// ===============================

if (isCaseWorker &&
    _application.status == "Draft") ...[

  SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: workflowAction(context, () async {

      final latestApplication =
          await ApplicationRepository().getById(
        _application.id!,
      );

      if (!mounted) return;

      if (latestApplication == null) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(

            content: Text(
              "Application not found.",
            ),

          ),

        );

        return;

      }

      final result = await Navigator.push(

        context,

        MaterialPageRoute(

          builder: (_) => NewApplicationScreen(

            application: latestApplication,

          ),

        ),

      );

      if (!mounted) return;

      if (result == true) {

        Navigator.pop(context, true);

      }

    }),

    child: const Text(
      "EDIT",
    ),

  ),
),

  const SizedBox(height: 10),

  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: workflowAction(context, () async {

    await ApplicationRepository().submitToDRFO(_application);

        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(

            content: Text(
              "Application Submitted to DRFO",
            ),

          ),

        );

        Navigator.pop(context, true);

      }),

      child: const Text(
        "SUBMIT TO DRFO",
      ),

    ),

  ),

  const SizedBox(height: 10),

  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      onPressed: workflowAction(context, () {

      }),
      child: const Text(
        "DELETE",
      ),
    ),
  ),

],

// ===============================
// RFO
// ===============================

if (isRFO &&
    _application.status ==
        WorkflowStatus.pendingRFOApproval) ...[

  SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: workflowAction(context, () async {
  final governmentReply = await GovernmentApprovalRepository().get(_application.id!);
  final revenueReply = await RevenueReplyRepository().current(_application.id!);
  if (!context.mounted) return;
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => governmentReply?.stage == 'review' ? GovernmentApprovalScreen(application: _application, rfo: true) : revenueReply?.stage == 'review' ? RevenueReplyWorkflowScreen(application: _application, rfo: true) : RFODecisionScreen(
        application: _application,
      ),
    ),
  );

  if (!context.mounted) {
    return;
  }

  if (result == true) {
    Navigator.pop(context, true);
  }
}),
      child: const Text(
        "OPEN RFO DECISION",
      ),
    ),
  ),

],     
              ],
            ),
          ),
        ),
      ),
    );
  }
}