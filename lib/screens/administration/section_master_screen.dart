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

  final kannadaController = TextEditingController(

    text: item?["kannadaName"] ?? "",

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

                      labelText: "Section Name (English)",

                    ),

                  ),

                  const SizedBox(height: 15),

                  TextField(

                    controller: kannadaController,

                    decoration: const InputDecoration(

                      labelText: "Section Name (Kannada)",

                      hintText: "ವಿಭಾಗದ ಹೆಸರು",

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

        kannadaName: kannadaController.text.trim(),

        displayOrder:
            int.tryParse(displayOrderController.text) ?? 1,

        isActive: isActive,

      );

    } else {

      await SectionRepository().update(

        id: item["id"],

        sectionName: sectionController.text,

        kannadaName: kannadaController.text.trim(),

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

      onTap: () {

        showSectionDialog(

          item: item,

        );

      },

      onLongPress: () async {

        final confirm = await showDialog<bool>(

          context: context,

          builder: (_) => AlertDialog(

            title: const Text("Delete Section"),

            content: Text(
              'Delete "${item["sectionName"]}" ?',
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
          try {
            await SectionRepository().delete(item["id"]);

            loadSections();
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Cannot delete: $e",
                  ),
                ),
              );
            }
          }
        }

      },

      leading: CircleAvatar(

        child: Text("${index + 1}"),

      ),

      title: Text(item["sectionName"] ?? ""),

      subtitle: Text(
        (item["kannadaName"]?.toString() ?? "").isNotEmpty
            ? "${item["kannadaName"]} • Display Order : ${item["displayOrder"]}"
            : "Display Order : ${item["displayOrder"]}",
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

  showSectionDialog();

},

  child: const Icon(Icons.add),

),

);

  }

}