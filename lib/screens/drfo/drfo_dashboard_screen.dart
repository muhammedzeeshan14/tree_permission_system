import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../repositories/application_repository.dart';
import 'drfo_assignment_screen.dart';
import 'drfo_inspection_screen.dart';

import 'widgets/drfo_assignment_tab.dart';
import 'widgets/drfo_bfo_pending_tab.dart';
import 'widgets/drfo_verification_tab.dart';
import 'widgets/drfo_self_inspection_tab.dart';
import 'widgets/drfo_returned_tab.dart';
import 'widgets/drfo_forwarded_tab.dart';

import '../../widgets/dashboard_header.dart';
import '../../services/session_service.dart';
import '../../widgets/tpms_drawer.dart';
import '../../widgets/sync_bar.dart';

import 'bfo_progress_screen.dart';
import '../../constants/workflow_status.dart';
import 'drfo_self_inspection_wizard.dart';
import 'drfo_forwarded_application_screen.dart';

class DRFODashboardScreen extends StatefulWidget {
  const DRFODashboardScreen({super.key});

  @override
  State<DRFODashboardScreen> createState() =>
      _DRFODashboardScreenState();
}

class _DRFODashboardScreenState
    extends State<DRFODashboardScreen>
    with SingleTickerProviderStateMixin {

  late TabController tabController;

List<ApplicationModel> pendingAssignment = [];

List<ApplicationModel> pendingWithBFO = [];

List<ApplicationModel> pendingVerification = [];
List<ApplicationModel> pendingSelfInspection = [];

List<ApplicationModel> returnedApplications = [];
List<ApplicationModel> forwardedToRFO = [];

  @override
  void initState() {
    super.initState();

tabController = TabController(
length: 6,
  vsync: this,
);

loadApplications();
  }

  Future<void> loadApplications() async {

  final data = await ApplicationRepository()
      .getApplicationsForDRFO(
          SessionService.instance.sectionId!);

  pendingAssignment = data.where((e) {

    return e.status ==
       WorkflowStatus.pendingDRFOAssignment;

  }).toList();

  pendingWithBFO = data.where((e) {

    return e.status ==
        WorkflowStatus.pendingBFOInspection;

  }).toList();

  pendingVerification = data.where((e) {

    return e.status ==
       WorkflowStatus.pendingDRFOVerification;

  }).toList();

  pendingSelfInspection = data.where((e) {

  return e.status ==
      WorkflowStatus.pendingDRFOSelfInspection ||

      e.status ==
      WorkflowStatus.pendingDRFOReSelfInspection;

}).toList();

returnedApplications = data.where((e) {

  return e.status ==
          WorkflowStatus.returnedByRFO ||

      e.status ==
          WorkflowStatus.returnedToBFO;

}).toList();

forwardedToRFO = data.where((e) {

  return e.status ==
      WorkflowStatus.pendingRFOApproval;

}).toList();

  if (mounted) {
    setState(() {});
  }

}
  Future<void> _refresh() async {
    await loadApplications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refreshed'),
        ),
      );
    }
  }
Future<void> openAssignment(
    ApplicationModel app) async {

  await Navigator.push(

    context,

    MaterialPageRoute(

      builder: (_) =>

          DRFOAssignmentScreen(

        application: app,

      ),

    ),

  );

  await loadApplications();

}
Future<void> openPendingBFO(
    ApplicationModel app) async {

  await Navigator.push(

    context,

    MaterialPageRoute(

      builder: (_) =>

          BFOProgressScreen(

        application: app,

      ),

    ),

  );

}

Future<void> openSelfInspection(
    ApplicationModel app) async {

  await Navigator.push(

    context,

    MaterialPageRoute(

      builder: (_) =>
          DRFOSelfInspectionWizard(

        application: app,

      ),

    ),

  );

  await loadApplications();

}

Future<void> openVerification(
    ApplicationModel app) async {

  await Navigator.push(

    context,

    MaterialPageRoute(

      builder: (_) =>

          DRFOInspectionScreen(

        application: app,

      ),

    ),

  );

  await loadApplications();

}

Future<void> openForwardedApplication(
    ApplicationModel app) async {

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) =>
          DRFOForwardedApplicationScreen(
        application: app,
      ),
    ),
  );

  await loadApplications();
}

@override
void dispose() {

  tabController.dispose();

  super.dispose();

}

@override
Widget build(BuildContext context) {

 return Scaffold(

  drawer: const TPMSDrawer(),

    appBar: AppBar(

      centerTitle: true,

      title: const Text(
        "DRFO Dashboard",
      ),

      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
          onPressed: _refresh,
        ),
      ],

      bottom: TabBar(

        controller: tabController,

        isScrollable: true,

        tabAlignment: TabAlignment.start,

        tabs: const [

  Tab(text: "Assignment"),

  Tab(text: "With BFO"),

  Tab(text: "Self Inspect"),

  Tab(text: "Verification"),

  Tab(text: "Returned"),

  Tab(text: "Forwarded to RFO"),

],

      ),

    ),

    body: Column(

      children: [

        DashboardHeader(

          title: "🌳 Tree Permission Management System",

          officerName:
              SessionService.instance.name,

          designation:
              SessionService.instance.role,

          rangeName:
              SessionService.instance.rangeName,

        ),

        Expanded(

          child: TabBarView(

            controller: tabController,

            children: [

  DRFOAssignmentTab(
    applications: pendingAssignment,
    onOpen: openAssignment,
  ),

  DRFOBFOPendingTab(
    applications: pendingWithBFO,
    onOpen: openPendingBFO,
  ),

  DRFOSelfInspectionTab(
  applications: pendingSelfInspection,
  onOpen: openSelfInspection,
),

  DRFOVerificationTab(
    applications: pendingVerification,
    onOpen: openVerification,
  ),

  DRFOReturnedTab(
    applications: returnedApplications,
    onOpen: openVerification,
  ),

  DRFOForwardedTab(
  applications: forwardedToRFO,
  onOpen: openForwardedApplication,
),

],

          ),

        ),

      ],

    ),

    bottomNavigationBar: const SyncBar(),

  );

}

}