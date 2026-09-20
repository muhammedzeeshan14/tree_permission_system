import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../repositories/tree_count_verification_repository.dart';
import '../../repositories/master_repository.dart';
import '../bfo/tree/tree_count_home_screen.dart';

import '../bfo/tree/tree_count_summary_card.dart';

class TreeCountVerificationScreen extends StatefulWidget {

  final ApplicationModel application;

  const TreeCountVerificationScreen({

    super.key,

    required this.application,

  });

  @override
  State<TreeCountVerificationScreen> createState() =>
    TreeCountVerificationScreenState();
}

class TreeCountVerificationScreenState
    extends State<TreeCountVerificationScreen> {

  final verificationRepository =
      TreeCountVerificationRepository();

  final masterRepository =
      MasterRepository();

final GlobalKey<TreeCountSummaryCardState>
    summaryKey =
        GlobalKey<TreeCountSummaryCardState>();

  String? verification;

  List<String> reasons = [];

  @override
  void initState() {

    super.initState();

    load();

  }

  Future<void> load() async {

    final existing =
        await verificationRepository
            .getVerification(
      widget.application.id!,
    );

    if (existing != null) {

      verification =
          existing["verification"];

    }

    reasons =
        await masterRepository
            .getVerificationReasons(
      "TREE",
    );

    if (mounted) {

      setState(() {});

    }

  }

  bool validateVerification() {

    if (verification == null) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            "Please verify Tree Count.",
          ),

        ),

      );

      return false;

    }

    return true;

  }

Future<void> showReinspectDialog() async {

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

          items: reasons
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

                ScaffoldMessenger.of(context)
                    .showSnackBar(

                  const SnackBar(

                    content: Text(
                      "Please select a reason.",
                    ),

                  ),

                );

                return;

              }

              await verificationRepository
                  .saveVerification(

                applicationId:
                    widget.application.id!,

                verification:
                    "Re-inspect",

                reason: selectedReason,

              );

              if (!mounted) return;

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

    child: Column(

      children: [

        Expanded(

          child: SingleChildScrollView(

            child: Column(

              children: [

                TreeCountSummaryCard(
  key: summaryKey,
  applicationId: widget.application.id!,
),

                const SizedBox(height: 20),

                Card(

                  child: Padding(

                    padding:
                        const EdgeInsets.all(16),

                    child: Column(

                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [

                        const Text(

                          "Verification",

                          style: TextStyle(

                            fontSize: 18,

                            fontWeight:
                                FontWeight.bold,

                          ),

                        ),

                        const Divider(),

                        RadioListTile<String>(

                          value: "Correct",

                          groupValue:
                              verification,

                          title:
                              const Text("Correct"),

                          onChanged: (v) async {

                            verification = v;

                            setState(() {});

                            await verificationRepository
                                .saveVerification(

                              applicationId:
                                  widget.application.id!,

                              verification: v!,

                            );

                          },

                        ),

                        RadioListTile<String>(

                          value: "Modify",

                          groupValue:
                              verification,

                          title:
                              const Text("Modify"),

                          onChanged: (v) async {

                            verification = v;

                            setState(() {});

                            await verificationRepository
                                .saveVerification(

                              applicationId:
                                  widget.application.id!,

                              verification: v!,

                            );

                            await Navigator.push(

                              context,

                              MaterialPageRoute(

                                builder: (_) =>
                                    TreeCountHomeScreen(

                                  applicationId:
                                      widget.application.id!,

                                ),

                              ),

                            );

                            await summaryKey.currentState?.reload();

await load();

                          },

                        ),

                        RadioListTile<String>(

                          value: "Re-inspect",

                          groupValue:
                              verification,

                          title: const Text(
                                "Re-inspect",
                              ),

                          onChanged: (v) async {

                            verification = v;

                            setState(() {});

                            await verificationRepository
                                .saveVerification(

                              applicationId:
                                  widget.application.id!,

                              verification: v!,

                            );

                            await showReinspectDialog();

                          },

                        ),

                      ],

                    ),

                  ),

                ),

              ],

            ),

          ),

        ),

      ],

    ),

  );

}
}