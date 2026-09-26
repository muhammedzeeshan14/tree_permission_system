import 'package:flutter/material.dart';

import '../../repositories/master_repository.dart';

class RecommendationReasonMasterScreen extends StatefulWidget {
  const RecommendationReasonMasterScreen({super.key});

  @override
  State<RecommendationReasonMasterScreen> createState() =>
      _RecommendationReasonMasterScreenState();
}

class _RecommendationReasonMasterScreenState
    extends State<RecommendationReasonMasterScreen> {
  final MasterRepository repository = MasterRepository();

  List<Map<String, dynamic>> recommendationTypes = [];
  List<Map<String, dynamic>> reasons = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    recommendationTypes =
        await repository.getMasters("Recommendation Type");

    reasons =
        await repository.getMasters("Recommendation Reason");

    loading = false;

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> showReasonDialog({
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

  final displayOrderController =
      TextEditingController(
    text:
        item?["displayOrder"]?.toString() ?? "1",
  );

  bool isActive =
      (item?["isActive"] ?? 1) == 1;

  String selectedType =
      item?["parentCode"] ??
          (recommendationTypes.isNotEmpty
              ? recommendationTypes.first["code"]
              : "");

  await showDialog(

    context: context,

    builder: (dialogContext) {

      return StatefulBuilder(

        builder: (dialogContext,
            setDialogState) {

          return AlertDialog(

            title: Text(

              item == null
                  ? "Add Recommendation Reason"
                  : "Edit Recommendation Reason",

            ),

            content: SizedBox(

              width: 450,

              child: SingleChildScrollView(

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    DropdownButtonFormField<String>(

                      value: selectedType,

                      decoration:
                          const InputDecoration(

                        labelText:
                            "Recommendation Type",

                      ),

                      items:
                          recommendationTypes.map((e) {

                        return DropdownMenuItem<String>(

                          value: e["code"],

                          child: Text(
                            e["value"],
                          ),

                        );

                      }).toList(),

                      onChanged: (value) {

                        setDialogState(() {

                          selectedType =
                              value!;

                        });

                      },

                    ),

                    const SizedBox(height: 15),

                    TextField(

                      controller:
                          valueController,

                      decoration:
                          const InputDecoration(

                        labelText:
                            "Reason",

                      ),

                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller:
                          kannadaNameController,

                      decoration:
                          const InputDecoration(
                        labelText:
                            "Kannada Letter Name",
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(

                      controller:
                          codeController,

                      decoration:
                          const InputDecoration(

                        labelText: "Code",

                      ),

                    ),

                    const SizedBox(height: 15),

                    TextField(

                      controller:
                          remarksController,

                      decoration:
                          const InputDecoration(

                        labelText:
                            "Remarks",

                      ),

                      maxLines: 2,

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

                      title:
                          const Text("Active"),

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

                  Navigator.pop(
                      dialogContext);

                },

                child: const Text("Cancel"),

              ),

              ElevatedButton(

                onPressed: () async {

                  if (item == null) {

                    await repository.insert(

                      masterType:
                          "Recommendation Reason",

                      value:
                          valueController.text,

                       kannadaName:
                           kannadaNameController.text,

                      code:
                          codeController.text,

                      parentCode:
                          selectedType,

                      displayOrder:

                          int.tryParse(
                                  displayOrderController
                                      .text) ??
                              1,

                      remarks:
                          remarksController.text,

                      isActive:
                          isActive,

                    );

                  } else {

                    await repository.update(

                      id: item["id"],

                      value:
                          valueController.text,

                       kannadaName:
                           kannadaNameController.text,

                      code:
                          codeController.text,

                      parentCode:
                          selectedType,

                      displayOrder:

                          int.tryParse(
                                  displayOrderController
                                      .text) ??
                              1,

                      remarks:
                          remarksController.text,

                      isActive:
                          isActive,

                    );

                  }

                  Navigator.pop(
                      dialogContext);

                  await loadData();

                },

                child:
                    const Text("Save"),

              ),

            ],

          );

        },

      );

    },

  );

}

  Future<void> deleteReason(int id) async {
    await repository.delete(id);

    await loadData();
  }

  String recommendationName(String parentCode) {
    final match = recommendationTypes.where(
      (e) => e["code"] == parentCode,
    );

    if (match.isEmpty) {
      return "";
    }

    return match.first["value"] ?? "";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recommendation Reasons"),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showReasonDialog();
        },
        child: const Icon(Icons.add),
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : reasons.isEmpty
              ? const Center(
                  child: Text(
                    "No Recommendation Reasons",
                  ),
                )
              : ListView.builder(
                  itemCount: reasons.length,
                  itemBuilder: (context, index) {
                    final item = reasons[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: ListTile(
                        title: Text(
                          item["value"] ?? "",
                        ),

                        subtitle: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [

                            Text(
                              "Type : ${recommendationName(item["parentCode"] ?? "")}",
                            ),

                            Text(
                              "Code : ${item["code"] ?? ""}",
                            ),

                            Text(
                              item["isActive"] == 1
                                  ? "Active"
                                  : "Inactive",
                            ),
                          ],
                        ),

                        onTap: () {
                          showReasonDialog(
                            item: item,
                          );
                        },

                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            deleteReason(item["id"]);
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}