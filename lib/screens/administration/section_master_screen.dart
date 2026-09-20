import 'package:flutter/material.dart';
import '../../repositories/section_repository.dart';

class SectionMasterScreen extends StatefulWidget {

  const SectionMasterScreen({super.key});

  @override
  State<SectionMasterScreen> createState() =>
      _SectionMasterScreenState();

}

class _SectionMasterScreenState
    extends State<SectionMasterScreen> {
      List<Map<String, dynamic>> sections = [];
      @override
void initState() {
  super.initState();

  loadSections();
}

Future<void> loadSections() async {

  sections =
      await SectionRepository().getAll();

  if (mounted) {
    setState(() {});
  }

}
Future<void> showSectionDialog({

  Map<String, dynamic>? item,

}) async {

  final sectionController = TextEditingController(

    text: item?["sectionName"] ?? "",

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

                  ? "Add Section"

                  : "Edit Section",

            ),

            content: SizedBox(

              width: 400,

              child: Column(

                mainAxisSize: MainAxisSize.min,

                children: [

                  TextField(

                    controller: sectionController,

                    decoration: const InputDecoration(

                      labelText: "Section Name",

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

            actions: [

              TextButton(

                onPressed: () {

                  Navigator.pop(dialogContext);

                },

                child: const Text("Cancel"),

              ),

              ElevatedButton(

              onPressed: () async {

  try {

    if (item == null) {

      await SectionRepository().insert(

        sectionName: sectionController.text,

        displayOrder:
            int.tryParse(displayOrderController.text) ?? 1,

        isActive: isActive,

      );

    } else {

      await SectionRepository().update(

        id: item["id"],

        sectionName: sectionController.text,

        displayOrder:
            int.tryParse(displayOrderController.text) ?? 1,

        isActive: isActive,

      );

    }

    Navigator.pop(dialogContext);

    loadSections();

  } catch (e) {

    debugPrint("SECTION ERROR: $e");

  }

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

        title: const Text("Section Master"),

      ),

      body: ListView.builder(

  itemCount: sections.length,

  itemBuilder: (context, index) {

    final item = sections[index];

    return ListTile(

      leading: CircleAvatar(

        child: Text("${index + 1}"),

      ),

      title: Text(item["sectionName"] ?? ""),

      subtitle: Text(

        "Display Order : ${item["displayOrder"]}",

      ),

    );

  },

),

floatingActionButton: FloatingActionButton(

 onPressed: () {

  showSectionDialog();

},

  child: const Icon(Icons.add),

),

);

  }

}