import 'package:flutter/material.dart';

import '../repositories/permission_type_repository.dart';

class PermissionTypeMasterScreen extends StatefulWidget {
  const PermissionTypeMasterScreen({super.key});

  @override
  State<PermissionTypeMasterScreen> createState() =>
      _PermissionTypeMasterScreenState();
}

class _PermissionTypeMasterScreenState
    extends State<PermissionTypeMasterScreen> {

  final repo = PermissionTypeRepository();

  List<Map<String, dynamic>> data = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {

    data = await repo.getAll();

    if (mounted) {
      setState(() {});
    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(
          "Permission Types",
        ),

      ),

      floatingActionButton: FloatingActionButton(

        onPressed: () {

          openEditor();

        },

        child: const Icon(Icons.add),

      ),

      body: ListView.builder(

        itemCount: data.length,

        itemBuilder: (context, index) {

          final item = data[index];

          return Card(

            child: ListTile(

              title: Text(
                item["permissionType"],
              ),

              subtitle: Text(
                "Display Order : ${item["displayOrder"]}",
              ),

              trailing: IconButton(

                icon: const Icon(Icons.edit),

                onPressed: () {

                  openEditor(item);

                },

              ),

            ),

          );

        },

      ),

    );

  }

  Future<void> openEditor([
    Map<String, dynamic>? item,
  ]) async {

    final controller = TextEditingController(
      text: item?["permissionType"] ?? "",
    );

    final displayController =
        TextEditingController(
      text:
          (item?["displayOrder"] ?? 1).toString(),
    );

    bool active =
        (item?["isActive"] ?? 1) == 1;

    await showDialog(

      context: context,

      builder: (context) {

        return AlertDialog(

          title: Text(
            item == null
                ? "Add Permission Type"
                : "Edit Permission Type",
          ),

          content: StatefulBuilder(

            builder: (context, setDialog) {

              return SizedBox(

                width: 350,

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    TextField(

                      controller: controller,

                      decoration:
                          const InputDecoration(

                        labelText:
                            "Permission Type",

                      ),

                    ),

                    const SizedBox(height: 15),

                    TextField(

                      controller:
                          displayController,

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

                      value: active,

                      title: const Text(
                        "Active",
                      ),

                      onChanged: (v) {

                        setDialog(() {

                          active = v;

                        });

                      },

                    ),

                  ],

                ),

              );

            },

          ),

          actions: [

            TextButton(

              onPressed: () {

                Navigator.pop(context);

              },

              child: const Text("Cancel"),

            ),

            ElevatedButton(

              onPressed: () async {

                if (item == null) {

                  await repo.insert(

                    permissionType:
                        controller.text.trim(),

                    displayOrder:
                        int.tryParse(
                              displayController.text,
                            ) ??
                            1,

                    isActive: active,

                  );

                } else {

                  await repo.update(

                    id: item["id"],

                    permissionType:
                        controller.text.trim(),

                    displayOrder:
                        int.tryParse(
                              displayController.text,
                            ) ??
                            1,

                    isActive: active,

                  );

                }

                if (!mounted) return;

                Navigator.pop(context);

                await load();

              },

              child: const Text("Save"),

            ),

          ],

        );

      },

    );

  }

}