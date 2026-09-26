import 'package:flutter/material.dart';

import '../repositories/application_type_repository.dart';
import '../repositories/permission_type_repository.dart';
import '../repositories/application_type_permission_mapping_repository.dart';

class ApplicationPermissionMappingScreen extends StatefulWidget {

  const ApplicationPermissionMappingScreen({
    super.key,
  });

  @override
  State<ApplicationPermissionMappingScreen> createState() =>
      _ApplicationPermissionMappingScreenState();
}

class _ApplicationPermissionMappingScreenState
    extends State<ApplicationPermissionMappingScreen> {

  final applicationRepo =
      ApplicationTypeRepository();

  final permissionRepo =
      PermissionTypeRepository();

  final mappingRepo =
      ApplicationTypePermissionMappingRepository();

  List<Map<String, dynamic>> applicationTypes = [];

  List<Map<String, dynamic>> permissionTypes = [];

  final Map<int, int?> selectedPermission = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {

    applicationTypes =
        await applicationRepo.getAll();

    permissionTypes =
        await permissionRepo.getAll();

    final mappings =
        await mappingRepo.getAll();

    selectedPermission.clear();

    for (final app in applicationTypes) {

      selectedPermission[app["id"]] = null;

    }

    for (final map in mappings) {

      selectedPermission[
          map["applicationTypeId"]] =
          map["permissionTypeId"];

    }

    if (mounted) {
      setState(() {});
    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Application → Permission Mapping",
        ),

      ),

      body: Padding(

  padding: const EdgeInsets.all(16),

  child: Column(

    children: [

      Container(

        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),

        decoration: BoxDecoration(

          color: Colors.green.shade50,

          border: Border.all(
            color: Colors.green,
          ),

        ),

        child: const Row(

          children: [

            Expanded(
              flex: 5,
              child: Text(

                "Application Type",

                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),

              ),
            ),

            Expanded(
              flex: 5,
              child: Text(

                "Permission Type",

                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),

              ),
            ),

          ],

        ),

      ),

      Expanded(

        child: ListView.builder(

          itemCount: applicationTypes.length,

          itemBuilder: (context, index) {

            final app = applicationTypes[index];

            return Padding(

              padding: const EdgeInsets.symmetric(
                vertical: 6,
              ),

              child: Row(

                children: [

                  Expanded(

                    flex: 5,

                    child: Padding(

                      padding: const EdgeInsets.only(
                        left: 8,
                      ),

                      child: Text(

                        app["applicationType"],

                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),

                      ),

                    ),

                  ),

                  Expanded(

                    flex: 5,

                    child: DropdownButtonFormField<int>(

                      initialValue: selectedPermission[
                          app["id"]],

                      decoration:
                          const InputDecoration(
                            hintText: "Select",

                        isDense: true,

                        border:
                            OutlineInputBorder(),

                      ),

                      items:
                          permissionTypes.map((p) {

                        return DropdownMenuItem<int>(

                          value: p["id"],

                          child: Text(
  p["permissionType"],
  overflow: TextOverflow.ellipsis,
),

                        );

                      }).toList(),

                      onChanged: (value) {

                        setState(() {

                          selectedPermission[
                              app["id"]] = value;

                        });

                      },

                    ),

                  ),

                ],

              ),

            );

          },

        ),

      ),

    ],

  ),

),

      bottomNavigationBar: SafeArea(

  child: Padding(

    padding: const EdgeInsets.all(12),

    child: SizedBox(

      height: 50,

      child: ElevatedButton.icon(

        onPressed: save,

        icon: const Icon(Icons.save),

        label: const Text(

          "SAVE MAPPING",

        ),

      ),

    ),

  ),

),

    );

  }

  Future<void> save() async {

    for (final app in applicationTypes) {

      final permissionId =
          selectedPermission[app["id"]];

      if (permissionId == null) continue;

      await mappingRepo.saveMapping(

        applicationTypeId: app["id"],

        permissionTypeId: permissionId,

      );

    }

await load();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(

        content: Text(
          "Mappings Saved Successfully",
        ),

      ),

    );

  }

}