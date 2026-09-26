import 'package:flutter/material.dart';
import 'office_configuration_screen.dart';
import 'officer_directory_screen.dart';
import 'application_type_master_screen.dart';
import 'master_menu_screen.dart';
import 'storage_management_screen.dart';
import '../../services/session_service.dart';

class AdministrationScreen extends StatelessWidget {

  const AdministrationScreen({super.key});

  Widget menu(
      BuildContext context,
      String title,
      IconData icon,
      VoidCallback onTap) {

    return Card(

      elevation: 3,

      child: ListTile(

        leading: Icon(
          icon,
          color: Colors.green,
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        trailing: const Icon(Icons.arrow_forward_ios),

        onTap: onTap,

      ),

    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Administration"),
      ),

      body: ListView(

        padding: const EdgeInsets.all(10),

        children: [

          menu(
  context,
  "Office Configuration",
  Icons.business,
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const OfficeConfigurationScreen(),
      ),
    );
  },
),

          menu(
  context,
  "Application Type Master",
  Icons.category,
  () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const ApplicationTypeMasterScreen(),
      ),
    );
  },
),
menu(
  context,
  "Masters",
  Icons.dataset,
  () {

    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) => const MasterMenuScreen(),

      ),

    );

  },
),

          menu(
            context,
            "Officers",
            Icons.people,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OfficerDirectoryScreen())),
          ),

          if (SessionService.instance.role
                  .trim()
                  .toUpperCase() ==
              "RFO")
            menu(
              context,
              "Storage Management",
              Icons.cloud_off,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const StorageManagementScreen())),
            ),

          menu(
            context,
            "Templates",
            Icons.description,
            () {},
          ),

        ],

      ),

    );

  }

}