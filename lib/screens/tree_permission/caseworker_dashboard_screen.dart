import 'revenue_reply_screen.dart';
import 'government_approval_screen.dart';
import 'package:flutter/material.dart';

import '../../services/session_service.dart';
import '../../widgets/tpms_drawer.dart';
import '../../widgets/sync_bar.dart';
import 'application_list_screen.dart';
import 'new_application_screen.dart';
import 'approved_rfo_letters_screen.dart';

class CaseWorkerDashboardScreen extends StatefulWidget {
  const CaseWorkerDashboardScreen({
    super.key,
  });

  @override
  State<CaseWorkerDashboardScreen> createState() =>
      _CaseWorkerDashboardScreenState();
}

class _CaseWorkerDashboardScreenState
    extends State<CaseWorkerDashboardScreen> {
  Future<void> _refresh() async {
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Refreshed'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    final session =
        SessionService.instance;

    return Scaffold(

  drawer: const TPMSDrawer(),

      appBar: AppBar(

        centerTitle: true,

        title: const Text(
          "Case Worker Dashboard",
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refresh,
          ),
        ],

      ),

      body: ListView(

        padding: const EdgeInsets.all(16),

        children: [

          Card(

            elevation: 4,

            child: Padding(

              padding:
                  const EdgeInsets.all(16),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(

                    "Welcome",

                    style: TextStyle(

                      fontSize: 16,

                    ),

                  ),

                  const SizedBox(height: 5),

                  Text(

                    session.name,

                    style: const TextStyle(

                      fontSize: 22,

                      fontWeight:
                          FontWeight.bold,

                    ),

                  ),

                  const SizedBox(height: 8),

                  Text(

                    "Role : ${session.role}",

                  ),

                ],

              ),

            ),

          ),

          const SizedBox(height: 15),

          Card(

            child: ListTile(

              leading: const Icon(

                Icons.add_circle,

                color: Colors.green,

              ),

              title: const Text(

                "New Application",

              ),

              subtitle: const Text(

                "Create new tree permission application",

              ),

              trailing:
                  const Icon(Icons.arrow_forward_ios),

              onTap: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (_) =>
                        const NewApplicationScreen(),

                  ),

                );

              },

            ),

          ),
                    const SizedBox(height: 15),

          Card(

            child: ListTile(

              leading: const Icon(

                Icons.folder,

                color: Colors.blue,

              ),

              title: const Text(

                "My Applications",

              ),

              subtitle: const Text(

                "View applications created by you",

              ),

              trailing: const Icon(

                Icons.arrow_forward_ios,

              ),

              onTap: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (_) =>

                        const ApplicationListScreen(),

                  ),

                );

              },

            ),

          ),

          const SizedBox(height: 15),

          Card(
  child: ListTile(
    leading: const Icon(
      Icons.print,
      color: Colors.green,
    ),
    title: const Text(
      "Approved RFO - Print Letters",
    ),
    subtitle: const Text(
      "View and print documents approved by RFO",
    ),
    trailing: const Icon(
      Icons.arrow_forward_ios,
    ),
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              const ApprovedRfoLettersScreen(),
        ),
      );
    },
  ),
),

const SizedBox(height: 15),
Card(child: ListTile(leading: const Icon(Icons.account_balance, color: Colors.orange), title: const Text('Pending Government land approvals'), subtitle: const Text('Print document requests and enter received details'), trailing: const Icon(Icons.arrow_forward_ios), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingGovernmentApprovalsScreen())))),
Card(child: ListTile(leading: const Icon(Icons.hourglass_empty, color: Colors.orange), title: const Text('Pending Revenue Opinion'), subtitle: const Text('Enter replies received from the revenue authority'), trailing: const Icon(Icons.arrow_forward_ios), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PendingRevenueOpinionScreen())))),
        ],

      ),

      bottomNavigationBar: const SyncBar(),

    );

  }

}