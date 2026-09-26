import 'package:flutter/material.dart';

import '../../repositories/master_repository.dart';

class GenericMasterScreen extends StatefulWidget {

  final String masterType;

  final String title;

  const GenericMasterScreen({

    super.key,

    required this.masterType,

    required this.title,

  });

  @override
State<GenericMasterScreen> createState() =>
    _GenericMasterScreenState();
}

class _GenericMasterScreenState
    extends State<GenericMasterScreen> {

  List<Map<String, dynamic>> masters = [];
    List<Map<String, dynamic>> whyRemovingMasters = [];

  bool get isPurposeMaster =>
      widget.masterType == "Purpose";

  @override
  void initState() {
    super.initState();
    loadData();
  }

    Future<void> loadData() async {
    final repository = MasterRepository();

    masters = await repository.getMasters(
      widget.masterType,
    );

    if (isPurposeMaster) {
      final allWhyRemoving =
          await repository.getMasters(
        "Why Removing",
      );

      whyRemovingMasters = allWhyRemoving
          .where((item) => item["isActive"] == 1)
          .toList();
    } else {
      whyRemovingMasters = [];
    }

    if (mounted) {
      setState(() {});
    }
  }

Future<void> showMasterDialog({

  Map<String, dynamic>? item,

}) async {

  final valueController = TextEditingController(
    text: item?["value"] ?? "",
  );

  final kannadaNameController = TextEditingController(
  text: item?["kannadaName"] ?? "",
);

  final codeController = TextEditingController(
    text: item?["code"] ?? "",
  );

  final remarksController = TextEditingController(
    text: item?["remarks"] ?? "",
  );

  final displayOrderController = TextEditingController(
    text: item?["displayOrder"]?.toString() ?? "1",
  );

  String? selectedWhyRemovingCode =
      item?["parentCode"]?.toString();

  if (selectedWhyRemovingCode != null &&
      selectedWhyRemovingCode!.trim().isEmpty) {
    selectedWhyRemovingCode = null;
  }

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
                  ? "Add ${widget.title}"
                  : "Edit ${widget.title}",
            ),

            content: SizedBox(

              width: 450,

              child: SingleChildScrollView(

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    if (isPurposeMaster) ...[
                      DropdownButtonFormField<String>(
                        value: whyRemovingMasters.any(
                          (parent) =>
                              parent["code"]
                                  ?.toString() ==
                              selectedWhyRemovingCode,
                        )
                            ? selectedWhyRemovingCode
                            : null,
                        decoration:
                            const InputDecoration(
                          labelText:
                              "Related Why Removing",
                          border:
                              OutlineInputBorder(),
                        ),
                        items:
                            whyRemovingMasters.map((parent) {
                          return DropdownMenuItem<String>(
                            value: parent["code"]
                                    ?.toString() ??
                                "",
                            child: Text(
                              parent["value"]
                                      ?.toString() ??
                                  "",
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setDialogState(() {
                            selectedWhyRemovingCode =
                                value;
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                    ],

                    TextField(
                      controller: valueController,
                      decoration: InputDecoration(
                        labelText: widget.title,
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
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: "Code",
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: remarksController,
                      decoration: const InputDecoration(
                        labelText: "Remarks",
                      ),
                      maxLines: 2,
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: displayOrderController,
                      keyboardType:
                          TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Display Order",
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

                  if (isPurposeMaster &&
                      (selectedWhyRemovingCode == null ||
                          selectedWhyRemovingCode!
                              .trim()
                              .isEmpty)) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please select the related Why Removing.",
                        ),
                      ),
                    );
                    return;
                  }

                  if (item == null) {

                    await MasterRepository().insert(

                      masterType: widget.masterType,

                      value: valueController.text,

                      code: codeController.text,

                                            parentCode:
                          isPurposeMaster
                              ? selectedWhyRemovingCode!
                              : "",

                      kannadaName:
    kannadaNameController.text.trim(),

                      displayOrder:
                          int.tryParse(
                              displayOrderController.text) ??
                              1,

                      remarks:
                          remarksController.text,

                      isActive: isActive,

                    );

                  } else {

                    await MasterRepository().update(

                      id: item["id"],

                      value: valueController.text,

                      code: codeController.text,

                                            parentCode:
                          isPurposeMaster
                              ? selectedWhyRemovingCode!
                              : item["parentCode"]
                                      ?.toString() ??
                                  "",

                      kannadaName:
    kannadaNameController.text.trim(),

                      displayOrder:
                          int.tryParse(
                              displayOrderController.text) ??
                              1,

                      remarks:
                          remarksController.text,

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

  String _whyRemovingName(
    String? parentCode,
  ) {
    if (parentCode == null ||
        parentCode.trim().isEmpty) {
      return "";
    }

    final matches = whyRemovingMasters.where(
      (item) =>
          item["code"]?.toString() == parentCode,
    );

    if (matches.isEmpty) {
      return parentCode;
    }

    return matches.first["value"]?.toString() ??
        parentCode;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: Text(widget.title),

      ),

      body: masters.isEmpty

    ? const Center(

        child: Text(

          "No Records Found",

          style: TextStyle(

            fontSize: 18,

          ),

        ),

      )

    : ListView.builder(

        itemCount: masters.length,

        itemBuilder: (context, index) {

          final item = masters[index];

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

                item["value"] ?? "",

              ),

              subtitle: Text(
                [
                  if (isPurposeMaster)
                    "Related to: ${_whyRemovingName(
                      item["parentCode"]?.toString(),
                    )}",
                  item["kannadaName"]?.toString() ??
                      "",
                  item["code"]?.toString() ?? "",
                ]
                    .where(
                      (value) =>
                          value.trim().isNotEmpty,
                    )
                    .join(" • "),
              ),

              trailing: Text(

                item["isActive"] == 1

                    ? "Active"

                    : "Inactive",

              ),
onTap: () {

  showMasterDialog(
    item: item,
  );

},
            ),

          );

        },

      ),
 floatingActionButton: FloatingActionButton(

  onPressed: () {

    showMasterDialog();

  },

  child: const Icon(Icons.add),

),

    );

  }

}