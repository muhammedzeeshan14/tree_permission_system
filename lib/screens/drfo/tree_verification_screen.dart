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
  Map<int, String> verificationReasons = {};

  Map<int, String> speciesMap = {};
  Map<int, String> treeStatusMap = {};
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
    verificationReasons.clear();

for (final tree in trees) {
  final status =
      await treeVerificationRepository
          .getVerification(tree.id!);

  if (status != null) {
    verificationStatus[tree.id!] = status;
  }

  final reason =
      await treeVerificationRepository
          .getVerificationReason(tree.id!);

  if (reason != null && reason.trim().isNotEmpty) {
    verificationReasons[tree.id!] = reason;
  }
}

    final species =
        await masterRepository.getSpecies();

    speciesMap = {
      for (final item in species)
        item["id"] as int:
            item["value"].toString(),
    };

    final treeStatuses =
        await masterRepository.getMasters(
      "Tree Status",
    );

    treeStatusMap = {
      for (final item in treeStatuses)
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

    if (verificationStatus[tree.id!] == "Re-inspect" &&
        (verificationReasons[tree.id!]?.trim().isEmpty ?? true)) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(

            "Please select a re-inspection reason for Tree No. ${tree.treeNumber}.",

          ),

        ),

      );

      return false;
    }
  }

  return true;
}
Future<String?> _showReinspectDialog(
  TreeModel tree,
) async {

  String? selectedReason;

  final existing = verificationReasons[tree.id!];
  if (existing != null && existing.trim().isNotEmpty) {
    selectedReason = existing;
  }

  return showDialog<String?>(
    context: context,
    builder: (_) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(

        title: const Text(
          "Reason for Re-inspection",
        ),

        content: DropdownButtonFormField<String>(

          value: treeVerificationReasons.contains(
                  selectedReason)
              ? selectedReason
              : null,

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
            setDialogState(() {
              selectedReason = v;
            });
          },

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

              if (selectedReason == null) {
                return;
              }

              Navigator.pop(
                  dialogContext, selectedReason);

            },

            child: const Text("OK"),

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

    return Padding(

  padding: const EdgeInsets.all(16),

  child: SingleChildScrollView(

    child: TreeInspectionTable(

          trees: trees,

          speciesMap: speciesMap,

          treeStatusMap: treeStatusMap,

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

  final previousStatus = verificationStatus[tree.id!];
  final previousReason = verificationReasons[tree.id!];

  setState(() {
    verificationStatus[tree.id!] = v;
  });

  final reason = await _showReinspectDialog(tree);

  if (reason == null) {
    setState(() {
      if (previousStatus == null) {
        verificationStatus.remove(tree.id!);
      } else {
        verificationStatus[tree.id!] = previousStatus;
      }
      if (previousReason == null) {
        verificationReasons.remove(tree.id!);
      } else {
        verificationReasons[tree.id!] = previousReason;
      }
    });
    return;
  }

  setState(() {
    verificationReasons[tree.id!] = reason;
  });

  await treeVerificationRepository
      .saveVerification(
    treeId: tree.id!,
    verification: v,
    verificationReason: reason,
  );
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