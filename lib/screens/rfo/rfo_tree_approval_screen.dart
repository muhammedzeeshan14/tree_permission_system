import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../models/tree_model.dart';

import '../../repositories/tree_repository.dart';
import '../../repositories/master_repository.dart';
import '../../repositories/tree_verification_repository.dart';

import '../../widgets/tree_inspection_table.dart';
import '../bfo/tree/add_edit_tree_screen.dart';

class TreeVerificationScreen extends StatefulWidget {
  final ApplicationModel application;

  const TreeVerificationScreen({
    super.key,
    required this.application,
  });

  @override
State<TreeVerificationScreen> createState() =>
    TreeVerificationScreenState();
}

class TreeVerificationScreenState
    extends State<TreeVerificationScreen> {

  final TreeRepository treeRepository =
      TreeRepository();

  final TreeVerificationRepository
    treeVerificationRepository =
        TreeVerificationRepository();

  final MasterRepository masterRepository =
      MasterRepository();
  List<TreeModel> trees = [];
  Map<int, String> verificationStatus = {};

  Map<int, String> speciesMap = {};
  Map<int, String> recommendationTypeMap = {};
  Map<int, String> recommendationReasonMap = {};
  List<String> treeVerificationReasons = [];

  

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {

    trees = await treeRepository.getTrees(
      widget.application.id!,
    );

    verificationStatus.clear();

for (final tree in trees) {
  final status =
      await treeVerificationRepository
          .getVerification(tree.id!);

  if (status != null) {
    verificationStatus[tree.id!] = status;
  }
}

    final species =
        await masterRepository.getSpecies();

    speciesMap = {
      for (final item in species)
        item["id"] as int:
            item["value"].toString(),
    };

    final recommendationTypes =
        await masterRepository.getMasters(
      "Recommendation Type",
    );

    recommendationTypeMap = {
      for (final item in recommendationTypes)
        item["id"] as int:
            item["value"].toString(),
    };

    final recommendationReasons =
        await masterRepository.getMasters(
      "Recommendation Reason",
    );

    recommendationReasonMap = {
      for (final item in recommendationReasons)
        item["id"] as int:
            item["value"].toString(),
    };

treeVerificationReasons =
    await masterRepository.getVerificationReasons(
  "TREE",
);

    if (mounted) {
      setState(() {});
    }
  }

bool validateVerification() {

  for (final tree in trees) {

    if (!verificationStatus.containsKey(tree.id!)) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(

            "Please verify Tree No. ${tree.treeNumber} before proceeding.",

          ),

        ),

      );

      return false;
    }
  }

  return true;
}
Future<void> _showReinspectDialog(
  TreeModel tree,
) async {

  String? selectedReason;

  await showDialog(

    context: context,

    builder: (_) {

      return AlertDialog(

        title: const Text(
          "Reason for Re-inspection",
        ),

        content: DropdownButtonFormField<String>(

          value: selectedReason,

          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),

          items: treeVerificationReasons
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
              .toList(),

          onChanged: (v) {
            selectedReason = v;
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

              if (selectedReason == null) {
                return;
              }

              // We'll save this in the next patch.

              Navigator.pop(context);

            },

            child: const Text("OK"),

          ),

        ],

      );

    },

  );

}

  @override
  Widget build(BuildContext context) {

    return Padding(

  padding: const EdgeInsets.all(16),

  child: SingleChildScrollView(

    child: TreeInspectionTable(

          trees: trees,

          speciesMap: speciesMap,

          recommendationTypeMap:
              recommendationTypeMap,

          recommendationReasonMap:
              recommendationReasonMap,

          showVerification: true,

          verificationBuilder: (tree) {

  final value = verificationStatus[tree.id!];

  return Padding(
    padding: const EdgeInsets.all(4),
    child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [

    RadioListTile<String>(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: const Text(
        "Correct",
        style: TextStyle(fontSize: 12),
      ),
      value: "Correct",
      groupValue: value,
      onChanged: (v) async {

  if (v == null) return;

  setState(() {
    verificationStatus[tree.id!] = v;
  });

  await treeVerificationRepository
      .saveVerification(
    treeId: tree.id!,
    verification: v,
  );
},
    ),

    RadioListTile<String>(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: const Text(
        "Modify",
        style: TextStyle(fontSize: 12),
      ),
      value: "Modify",
      groupValue: value,
      onChanged: (v) async {

  debugPrint("========== MODIFY CLICKED ==========");
  debugPrint("Tree ID : ${tree.id}");
  debugPrint("Tree No : ${tree.treeNumber}");

  if (v == null) return;

  setState(() {
    verificationStatus[tree.id!] = v;
  });

  await treeVerificationRepository.saveVerification(
    treeId: tree.id!,
    verification: v,
  );

  debugPrint("Opening AddEditTreeScreen...");

  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => AddEditTreeScreen(
        tree: tree,
        isEdit: true,
      ),
    ),
  );

  debugPrint("Returned from AddEditTreeScreen");

  await _load();
},
    ),

    RadioListTile<String>(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: const Text(
        "Re-inspect",
        style: TextStyle(fontSize: 12),
      ),
      value: "Re-inspect",
      groupValue: value,
      onChanged: (v) async {

  if (v == null) return;

  setState(() {
    verificationStatus[tree.id!] = v;
  });

  await treeVerificationRepository
      .saveVerification(
    treeId: tree.id!,
    verification: v,
  );

  await _showReinspectDialog(tree);
},
    ),

  ],
)
  );

},

                ),

      ),

    );

  }

}