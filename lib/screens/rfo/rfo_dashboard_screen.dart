import 'package:flutter/material.dart';

import '../administration/administration_screen.dart';
import '../tree_permission/application_list_screen.dart';
import '../../services/session_service.dart';
import '../login/login_screen.dart';
import '../../repositories/application_repository.dart';
import '../../widgets/tpms_drawer.dart';
import '../../widgets/sync_bar.dart';

class RFODashboardScreen extends StatelessWidget {
  const RFODashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

  drawer: const TPMSDrawer(),

      appBar: AppBar(

        centerTitle: true,

        title: const Text(
          "RFO Dashboard",
        ),

      ),

      body: ListView(

        padding: const EdgeInsets.all(15),

        children: [

          const SizedBox(height: 5),

          Card(

            elevation: 3,

            child: ListTile(

              leading: const Icon(
                Icons.assignment,
                color: Colors.blue,
              ),

              title: const Text(
  "Pending RFO Cases",
),

subtitle: const Text(
  "Applications pending final approval",
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

).then((_) {

  // Dashboard refresh

});

              },

            ),

          ),

          const SizedBox(height: 10),

          Card(

            elevation: 3,

            child: ListTile(

              leading: const Icon(
                Icons.search,
                color: Colors.orange,
              ),

              title: const Text(
                "Search Application",
              ),

              subtitle: const Text(
                "Search by Office Number",
              ),

              trailing: const Icon(
                Icons.arrow_forward_ios,
              ),

              onTap: () {

              },

            ),

          ),
                    const SizedBox(height: 10),

          Card(

            elevation: 3,

            child: ListTile(

              leading: const Icon(
                Icons.bar_chart,
                color: Colors.green,
              ),

              title: const Text(
                "Reports",
              ),

              subtitle: const Text(
  "Pending / Approved / Rejected Statistics",
),

              trailing: const Icon(
                Icons.arrow_forward_ios,
              ),

              onTap: () {

                ScaffoldMessenger.of(context).showSnackBar(

                  const SnackBar(

                    content: Text(
                      "Reports module coming soon.",
                    ),

                  ),

                );

              },

            ),

          ),

          const SizedBox(height: 10),

          Card(

            elevation: 3,

            child: ListTile(

              leading: const Icon(
                Icons.settings,
                color: Colors.deepPurple,
              ),

              title: const Text(
                "Administration",
              ),

              subtitle: const Text(
                "Masters and Office Configuration",
              ),

              trailing: const Icon(
                Icons.arrow_forward_ios,
              ),

              onTap: () {

                Navigator.push(

                  context,

                  MaterialPageRoute(

                    builder: (_) =>
                        const AdministrationScreen(),

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