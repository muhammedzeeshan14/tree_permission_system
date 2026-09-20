import 'package:flutter/material.dart';

import '../../repositories/beat_repository.dart';
import '../../repositories/section_repository.dart';

class BeatMasterScreen extends StatefulWidget {
  const BeatMasterScreen({super.key});

  @override
  State<BeatMasterScreen> createState() =>
      _BeatMasterScreenState();
}

class _BeatMasterScreenState
    extends State<BeatMasterScreen> {

  List<Map<String, dynamic>> beats = [];
  List<Map<String, dynamic>> sections = [];

  @override
void initState() {
  super.initState();

  loadBeats();

  loadSections();
}

  Future<void> loadBeats() async {

    beats = await BeatRepository().getAll();

    if (mounted) {
      setState(() {});
    }

  }
Future<void> loadSections() async {

  sections =
      await SectionRepository().getActive();

  if (mounted) {

    setState(() {});

  }

}
Future<void> showBeatDialog({

  Map<String, dynamic>? item,

}) async {

  int? selectedSectionId =
      item?["sectionId"];

  final beatController = TextEditingController(

    text: item?["beatName"] ?? "",

  );

  final displayOrderController = TextEditingController(

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

                  ? "Add Beat"

                  : "Edit Beat",

            ),

            content: SizedBox(

              width: 450,

              child: SingleChildScrollView(

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    DropdownButtonFormField<int>(

                      value: selectedSectionId,

                      decoration: const InputDecoration(

                        labelText: "Section",

                      ),

                      items: sections.map((section) {

                        return DropdownMenuItem<int>(

                          value: section["id"],

                          child: Text(

                            section["sectionName"],

                          ),

                        );

                      }).toList(),

                      onChanged: (value) {

                        setDialogState(() {

                          selectedSectionId = value;

                        });

                      },

                    ),

                    const SizedBox(height: 15),

                    TextField(

                      controller: beatController,

                      decoration: const InputDecoration(

                        labelText: "Beat Name",

                      ),

                    ),

                    const SizedBox(height: 15),

                    TextField(

                      controller: displayOrderController,

                      keyboardType: TextInputType.number,

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

                  if (selectedSectionId == null) {

                    ScaffoldMessenger.of(context).showSnackBar(

                      const SnackBar(

                        content: Text(

                          "Please select Section",

                        ),

                      ),

                    );

                    return;

                  }

                  if (item == null) {

                    await BeatRepository().insert(

                      sectionId: selectedSectionId!,

                      beatName: beatController.text,

                      displayOrder:

                          int.tryParse(

                                  displayOrderController.text) ??

                              1,

                      isActive: isActive,

                    );

                  } else {

                    await BeatRepository().update(

                      id: item["id"],

                      sectionId: selectedSectionId!,

                      beatName: beatController.text,

                      displayOrder:

                          int.tryParse(

                                  displayOrderController.text) ??

                              1,

                      isActive: isActive,

                    );

                  }

                  Navigator.pop(dialogContext);

                  loadBeats();

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

        title: const Text("Beat Master"),

      ),

      body: ListView.builder(

        itemCount: beats.length,

        itemBuilder: (context, index) {

          final item = beats[index];


           return ListTile(

  onTap: () {

    showBeatDialog(

      item: item,

    );

  },

  onLongPress: () async {

    final confirm = await showDialog<bool>(

      context: context,

      builder: (_) => AlertDialog(

        title: const Text("Delete Beat"),

        content: Text(

          'Delete "${item["beatName"]}" ?',

        ),

        actions: [

          TextButton(

            onPressed: () {

              Navigator.pop(context, false);

            },

            child: const Text("Cancel"),

          ),

          ElevatedButton(

            onPressed: () {

              Navigator.pop(context, true);

            },

            child: const Text("Delete"),

          ),

        ],

      ),

    );

    if (confirm == true) {

      await BeatRepository().delete(item["id"]);

      loadBeats();

    }

  },

  leading: CircleAvatar(

    child: Text("${index + 1}"),

  ),

  title: Text(

    item["beatName"] ?? "",

  ),

  subtitle: Text(

    item["sectionName"] ?? "",

  ),

  trailing: Icon(

    item["isActive"] == 1

        ? Icons.check_circle

        : Icons.cancel,

    color: item["isActive"] == 1

        ? Colors.green

        : Colors.red,

  ),

);

        },

      ),

      floatingActionButton: FloatingActionButton(

        onPressed: () {

  showBeatDialog();

},

        child: const Icon(Icons.add),

      ),

    );

  }

}