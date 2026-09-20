import 'package:flutter/material.dart';
import '../../repositories/application_type_repository.dart';

class ApplicationTypeMasterScreen extends StatefulWidget {

  const ApplicationTypeMasterScreen({super.key});

  @override
  State<ApplicationTypeMasterScreen> createState() =>
      _ApplicationTypeMasterScreenState();

}

class _ApplicationTypeMasterScreenState
    extends State<ApplicationTypeMasterScreen> {
      List<Map<String, dynamic>> applicationTypes = [];

@override
void initState() {
  super.initState();
  loadData();
}

Future<void> loadData() async {

  applicationTypes =
      await ApplicationTypeRepository().getAll();

  if (mounted) {
    setState(() {});
  }

}
Future<void> showApplicationTypeDialog({

  Map<String, dynamic>? item,

}) async {

  final applicationTypeController =

      TextEditingController(

    text: item?["applicationType"] ?? "",

  );

  final kannadaNameController =
    TextEditingController(
  text: item?["kannadaName"] ?? "",
);

  final shortCodeController =

      TextEditingController(

    text: item?["shortCode"] ?? "",

  );

  final displayOrderController =

      TextEditingController(

    text: item?["displayOrder"]?.toString() ?? "1",

  );

  bool isActive =

      (item?["isActive"] ?? 1) == 1;

  await showDialog(

    context: context,

    builder: (dialogContext) {

      return StatefulBuilder(

        builder: (dialogContext, setDialogState) {

          return AlertDialog(

            title: Text(

              item == null

                  ? "Add Application Type"

                  : "Edit Application Type",

            ),

            content: SizedBox(

              width: 400,

              child: SingleChildScrollView(

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    TextField(

                      controller:

                          applicationTypeController,

                      decoration:

                          const InputDecoration(

                        labelText:

                            "Application Type",

                      ),

                    ),

                    const SizedBox(height: 15),

TextField(
  controller: kannadaNameController,
  decoration: const InputDecoration(
    labelText: "Kannada Name",
  ),
),

const SizedBox(height: 15),

                    TextField(

                      controller:

                          shortCodeController,

                      decoration:

                          const InputDecoration(

                        labelText:

                            "Short Code",

                      ),

                    ),

                    const SizedBox(height: 15),

                    TextField(

                      controller:

                          displayOrderController,

                      keyboardType:

                          TextInputType.number,

                      decoration:

                          const InputDecoration(

                        labelText:

                            "Display Order",

                      ),

                    ),

                    const SizedBox(height: 15),

                    SwitchListTile(

                      title: const Text("Active"),

                      value: isActive,

                      onChanged: (value) {

                        setDialogState(() {

                          isActive = value;

                        });

                      },

                    ),

                  ],

                ),

              ),

            ),

            actions: [

              TextButton(

                onPressed: () {

                  Navigator.pop(dialogContext);

                },

                child: const Text("Cancel"),

              ),

              ElevatedButton(

                onPressed: () async {

                  if (item == null) {

                    await ApplicationTypeRepository()

                        .insert(

                      applicationType:

                          applicationTypeController.text,

                      kannadaName:
    kannadaNameController.text.trim(),

                      shortCode:

                          shortCodeController.text,

                      displayOrder: int.tryParse(

                              displayOrderController.text) ??

                          1,

                      isActive: isActive,

                    );

                  } else {

                    await ApplicationTypeRepository()

                        .update(

                      id: item["id"],

                      applicationType:

                          applicationTypeController.text,

                      kannadaName:
    kannadaNameController.text.trim(),

                      shortCode:

                          shortCodeController.text,

                      displayOrder: int.tryParse(

                              displayOrderController.text) ??

                          1,

                      isActive: isActive,

                    );

                  }

                  Navigator.pop(dialogContext);

                  loadData();

                },

                child: const Text("Save"),

              ),

            ],

          );

        },

      );

    },

  );

}
  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text("Application Type Master"),

      ),

      body: applicationTypes.isEmpty

    ? const Center(

        child: Text(

          "No Application Types Found",

          style: TextStyle(

            fontSize: 18,

          ),

        ),

      )

    : ListView.builder(

        itemCount: applicationTypes.length,

        itemBuilder: (context, index) {

          final item = applicationTypes[index];

          return Card(

            margin: const EdgeInsets.symmetric(

              horizontal: 10,

              vertical: 5,

            ),

            child: ListTile(

              leading: CircleAvatar(

                child: Text("${index + 1}"),

              ),

              title: Text(

                item["applicationType"],

              ),

              subtitle: Text(
  [
    item["kannadaName"]?.toString() ?? "",
    "Code: ${item["shortCode"]?.toString() ?? ""}",
  ].where((value) => value.trim().isNotEmpty).join(" • "),
),

              trailing: Text(

                item["isActive"] == 1

                    ? "Active"

                    : "Inactive",

              ),
onTap: () {

  showApplicationTypeDialog(
    item: item,
  );

},
            ),

          );

        },

      ),
          floatingActionButton: FloatingActionButton(

  onPressed: () {

    showApplicationTypeDialog();

  },

  child: const Icon(Icons.add),

),

    );

  }

}