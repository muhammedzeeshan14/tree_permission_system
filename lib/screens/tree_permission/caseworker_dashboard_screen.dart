import '../../widgets/dashboard_count_label.dart';
import '../../constants/workflow_status.dart';
import '../../repositories/application_repository.dart';
import '../../widgets/application_search_action.dart';
import '../../widgets/workflow_action.dart';
import 'revenue_reply_screen.dart';
import 'government_approval_screen.dart';
import 'package:flutter/material.dart';

import '../../services/session_service.dart';
import '../../widgets/tpms_drawer.dart';
import '../../widgets/sync_bar.dart';
import 'application_list_screen.dart';
import 'new_application_screen.dart';
import 'approved_rfo_letters_screen.dart';
import 'completed_applications_screen.dart';

class CaseWorkerDashboardScreen extends StatefulWidget {
  const CaseWorkerDashboardScreen({super.key});

  @override
  State<CaseWorkerDashboardScreen> createState() =>
      _CaseWorkerDashboardScreenState();
}

class _CaseWorkerDashboardScreenState extends State<CaseWorkerDashboardScreen> {
  Map<String, int>? counts;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final userId = SessionService.instance.userId!;
      final applications = await ApplicationRepository().getApplications(
        onlineEquals: {'createdBy': userId},
        onlineStatuses: [
          WorkflowStatus.draft,
          WorkflowStatus.pendingDRFOAssignment,
          WorkflowStatus.returnedToCaseWorker,
          WorkflowStatus.approved,
          WorkflowStatus.pendingGovernmentLandApprovals,
          WorkflowStatus.pendingRevenueOpinion,
          WorkflowStatus.completed,
        ],
      );
      final result = <String, int>{};
      for (final app in applications.where((a) => a.createdBy == userId)) {
        result.update(app.status, (n) => n + 1, ifAbsent: () => 1);
      }
      if (mounted)
        setState(() {
          counts = result;
        });
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load application counts: $error')),
        );
    }
  }

  int? countFor(List<String> statuses) => counts == null
      ? null
      : statuses.fold<int>(0, (sum, status) => sum + (counts![status] ?? 0));

  @override
  Widget build(BuildContext context) {
    final session = SessionService.instance;

    return Scaffold(
      drawer: const TPMSDrawer(),

      appBar: AppBar(
        centerTitle: true,

        title: const Text("Case Worker Dashboard"),

        actions: [
          const ApplicationSearchAction(),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: workflowAction(context, _refresh),
          ),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),

        children: [
          Card(
            elevation: 4,

            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Text("Welcome", style: TextStyle(fontSize: 16)),

                  const SizedBox(height: 5),

                  Text(
                    session.name,

                    style: const TextStyle(
                      fontSize: 22,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text("Role : ${session.role}"),
                ],
              ),
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading: const Icon(Icons.add_circle, color: Colors.green),

              title: const Text("New Application"),

              subtitle: const Text("Create new tree permission application"),

              trailing: const Icon(Icons.arrow_forward_ios),

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => const NewApplicationScreen(),
                  ),
                ).then((_) => _refresh());
              },
            ),
          ),
          const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading: const Icon(Icons.folder, color: Colors.blue),

              title: DashboardCountLabel(
                label: 'My Applications',
                count: countFor([
                  WorkflowStatus.draft,
                  WorkflowStatus.pendingDRFOAssignment,
                  WorkflowStatus.returnedToCaseWorker,
                ]),
              ),

              subtitle: const Text("View applications created by you"),

              trailing: const Icon(Icons.arrow_forward_ios),

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => const ApplicationListScreen(),
                  ),
                ).then((_) => _refresh());
              },
            ),
          ),

          const SizedBox(height: 15),

          Card(
            child: ListTile(
              leading: const Icon(Icons.print, color: Colors.green),
              title: DashboardCountLabel(
                label: 'Approved RFO - Print Letters',
                count: countFor([WorkflowStatus.approved]),
              ),
              subtitle: const Text("View and print documents approved by RFO"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ApprovedRfoLettersScreen(),
                  ),
                ).then((_) => _refresh());
              },
            ),
          ),

          const SizedBox(height: 15),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance, color: Colors.orange),
              title: DashboardCountLabel(
                label: 'Pending Government land approvals',
                count: countFor([
                  WorkflowStatus.pendingGovernmentLandApprovals,
                ]),
              ),
              subtitle: const Text(
                'Print document requests and enter received details',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PendingGovernmentApprovalsScreen(),
                ),
              ).then((_) => _refresh()),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.hourglass_empty, color: Colors.orange),
              title: DashboardCountLabel(
                label: 'Pending Revenue Opinion',
                count: countFor([WorkflowStatus.pendingRevenueOpinion]),
              ),
              subtitle: const Text(
                'Enter replies received from the revenue authority',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PendingRevenueOpinionScreen(),
                ),
              ).then((_) => _refresh()),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: DashboardCountLabel(
                label: 'Completed Applications',
                count: countFor([WorkflowStatus.completed]),
                positiveIsGreen: true,
              ),
              subtitle: const Text(
                'Final letters viewed/printed, or online permission route completed',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CompletedApplicationsScreen(),
                ),
              ).then((_) => _refresh()),
            ),
          ),
        ],
      ),

      bottomNavigationBar: const SyncBar(),
    );
  }
}
