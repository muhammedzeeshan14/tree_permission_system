import '../../widgets/dashboard_count_label.dart';
import '../../constants/workflow_status.dart';
import '../../widgets/application_search_action.dart';
import '../../widgets/workflow_action.dart';
import 'package:flutter/material.dart';

import '../administration/administration_screen.dart';
import '../tree_permission/application_list_screen.dart';
import 'rfo_reports_screen.dart';
import '../../services/session_service.dart';
import '../login/login_screen.dart';
import '../../repositories/application_repository.dart';
import '../../widgets/tpms_drawer.dart';
import '../../widgets/sync_bar.dart';

class RFODashboardScreen extends StatefulWidget {
  const RFODashboardScreen({super.key});

  @override
  State<RFODashboardScreen> createState() => _RFODashboardScreenState();
}

class _RFODashboardScreenState extends State<RFODashboardScreen> {
  int? pendingCount;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final applications = await ApplicationRepository().getApplications(
        onlineStatuses: [WorkflowStatus.pendingRFOApproval],
      );
      if (mounted)
        setState(() {
          pendingCount = applications
              .where((a) => a.status == WorkflowStatus.pendingRFOApproval)
              .length;
        });
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load application counts: $error')),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const TPMSDrawer(),

      appBar: AppBar(
        centerTitle: true,

        title: const Text("RFO Dashboard"),

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
        padding: const EdgeInsets.all(15),

        children: [
          const SizedBox(height: 5),

          Card(
            elevation: 3,

            child: ListTile(
              leading: const Icon(Icons.assignment, color: Colors.blue),

              title: DashboardCountLabel(
                label: 'Pending RFO Cases',
                count: pendingCount,
              ),

              subtitle: const Text("Applications pending final approval"),

              trailing: const Icon(Icons.arrow_forward_ios),

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => const ApplicationListScreen(),
                  ),
                ).then((_) {
                  _refresh();
                });
              },
            ),
          ),

          const SizedBox(height: 10),

          Card(
            elevation: 3,

            child: ListTile(
              leading: const Icon(Icons.search, color: Colors.orange),

              title: const Text("Search Application"),

              subtitle: const Text("Search all applications and file status"),

              trailing: const Icon(Icons.arrow_forward_ios),

              onTap: () => ApplicationSearchAction.open(context),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            elevation: 3,

            child: ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.green),

              title: const Text("Reports"),

              subtitle: const Text("Pending / Approved / Rejected Statistics"),

              trailing: const Icon(Icons.arrow_forward_ios),

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(builder: (_) => const RfoReportsScreen()),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          Card(
            elevation: 3,

            child: ListTile(
              leading: const Icon(Icons.settings, color: Colors.deepPurple),

              title: const Text("Administration"),

              subtitle: const Text("Masters and Office Configuration"),

              trailing: const Icon(Icons.arrow_forward_ios),

              onTap: () {
                Navigator.push(
                  context,

                  MaterialPageRoute(
                    builder: (_) => const AdministrationScreen(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),

      bottomNavigationBar: const SyncBar(),
    );
  }
}
