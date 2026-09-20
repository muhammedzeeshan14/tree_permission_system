import 'package:flutter/material.dart';

import '../../repositories/application_repository.dart';
import '../bfo/bfo_dashboard_screen.dart';
import '../drfo/drfo_dashboard_screen.dart';
import '../rfo/rfo_dashboard_screen.dart';
import '../tree_permission/application_list_screen.dart';
import '../tree_permission/new_application_screen.dart';
import '../administration/administration_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  Map<String, int> counts = {};

  @override
  void initState() {
    super.initState();
    loadCounts();
  }

  Future<void> loadCounts() async {
    counts = await ApplicationRepository().getDashboardCounts();

    if (mounted) {
      setState(() {});
    }
  }

  Widget statusCard(
      String title,
      int value,
      Color color,
      IconData icon,
      ) {
    return Card(
      elevation: 4,
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [

            Icon(icon,size:40,color:color),

            const SizedBox(height:10),

            Text(
              value.toString(),
              style: const TextStyle(
                fontSize:28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height:5),

            Text(
              title,
              textAlign: TextAlign.center,
            ),

          ],
        ),
      ),
    );
  }

  Widget menuCard(
      String title,
      IconData icon,
      VoidCallback onTap,
      ) {

    return InkWell(

      onTap: () async {

        onTap();

        loadCounts();

      },

      child: Card(

        elevation:5,

        child: SizedBox(

          width:200,

          height:130,

          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Icon(icon,size:45,color:Colors.green),

              const SizedBox(height:10),

              Text(

                title,

                style: const TextStyle(

                  fontWeight: FontWeight.bold,

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text("Tree Permission Management System"),

      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(15),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(

              "Application Status",

              style: TextStyle(

                fontSize:22,

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height:15),

            Wrap(

              spacing:15,

              runSpacing:15,

              children: [

                statusCard(
                    "Total",
                    counts["Total"] ?? 0,
                    Colors.blue,
                    Icons.folder),

                statusCard(
                    "Pending BFO",
                    counts["Pending BFO"] ?? 0,
                    Colors.orange,
                    Icons.forest),

                statusCard(
                    "Pending DRFO",
                    counts["Pending DRFO"] ?? 0,
                    Colors.deepPurple,
                    Icons.assignment),

                statusCard(
                    "Pending RFO",
                    counts["Pending RFO"] ?? 0,
                    Colors.teal,
                    Icons.verified),

                statusCard(
                    "Returned",
                    counts["Returned to DRFO"] ?? 0,
                    Colors.red,
                    Icons.undo),

                statusCard(
    "Completed",
    counts["Completed"] ?? 0,
    Colors.green,
    Icons.check_circle),

                statusCard(
                    "Rejected",
                    counts["Rejected"] ?? 0,
                    Colors.black,
                    Icons.cancel),

              ],

            ),

            const SizedBox(height:30),

            const Divider(),

            const SizedBox(height:20),

            Wrap(

              spacing:20,

              runSpacing:20,

              children: [

                menuCard(

                  "New Application",

                  Icons.add_circle,

                      () async {

                    await Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) => const NewApplicationScreen(),

                      ),

                    );

                  },

                ),

                menuCard(

                  "Application List",

                  Icons.folder,

                      () async {

                    await Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) => const ApplicationListScreen(),

                      ),

                    );

                  },

                ),

                menuCard(

                  "BFO Dashboard",

                  Icons.forest,

                      () async {

                    await Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) => const BFODashboardScreen(),

                      ),

                    );

                  },

                ),

                menuCard(

                  "DRFO Dashboard",

                  Icons.assignment,

                      () async {

                    await Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) => const DRFODashboardScreen(),

                      ),

                    );

                  },

                ),

                menuCard(

                  "RFO Dashboard",

                  Icons.verified,

                      () async {

                    await Navigator.push(

                      context,

                      MaterialPageRoute(

                        builder: (_) => const RFODashboardScreen(),

                      ),

                    );

                  },

                ),
                menuCard(

  "Administration",

  Icons.admin_panel_settings,

      () async {

    await Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) => const AdministrationScreen(),

      ),

    );

  },

),

              ],

            ),

          ],

        ),

      ),

    );

  }

}