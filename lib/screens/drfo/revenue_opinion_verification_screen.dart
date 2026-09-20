import 'package:flutter/material.dart';

import '../../models/application_model.dart';

import '../../repositories/application_revenue_opinion_repository.dart';
import '../../repositories/revenue_opinion_repository.dart';
import '../../repositories/revenue_opinion_verification_repository.dart';
import '../../repositories/master_repository.dart';
import '../bfo/wizard/revenue_opinion_step.dart';
import '../../models/revenue_opinion_model.dart';

class RevenueOpinionVerificationScreen extends StatefulWidget {

  final ApplicationModel application;

  const RevenueOpinionVerificationScreen({

    super.key,

    required this.application,

  });

  @override
  State<RevenueOpinionVerificationScreen> createState() =>
      RevenueOpinionVerificationScreenState();

}

class RevenueOpinionVerificationScreenState
    extends State<RevenueOpinionVerificationScreen> {

  final applicationRepository =
      ApplicationRevenueOpinionRepository();

  final revenueRepository =
      RevenueOpinionRepository();

  final verificationRepository =
      RevenueOpinionVerificationRepository();

  final masterRepository =
      MasterRepository();

  String revenueOpinion = "";

  String officeName = "";

  String officeAddress = "";

  String? verification;

  List<String> reasons = [];

  @override
  void initState() {

    super.initState();

    load();

  }

  Future<void> load() async {

    final application =
        await applicationRepository
            .getByApplication(
      widget.application.id!,
    );

    if (application != null) {

      final opinions =
          await revenueRepository.getAll();

      RevenueOpinionModel? opinion;

for (final item in opinions) {

  if (item.id == application.revenueOpinionId) {

    opinion = item;

    break;

  }

}

if (opinion != null) {

  revenueOpinion = opinion.revenueOpinion;

  officeName = opinion.officeName;

  officeAddress = opinion.officeAddress;

}
}
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
            "Please verify Revenue Opinion.",
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

          content:
              DropdownButtonFormField<String>(

            value: selectedReason,

            decoration:
                const InputDecoration(

              border:
                  OutlineInputBorder(),

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

              child: const Text(
                "Cancel",
              ),

            ),

            ElevatedButton(

              onPressed: () async {

                if (selectedReason == null) {

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

    child: SingleChildScrollView(

      child: Column(

        children: [

          Card(

            child: Padding(

              padding: const EdgeInsets.all(16),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(

                    "Revenue Opinion Details",

                    style: TextStyle(

                      fontSize: 18,

                      fontWeight:
                          FontWeight.bold,

                    ),

                  ),

                  const Divider(),

                  ListTile(

                    title: const Text(
                      "Revenue Opinion",
                    ),

                    subtitle: Text(
                      revenueOpinion,
                    ),

                  ),

                  ListTile(

                    title: const Text(
                      "Office",
                    ),

                    subtitle: Text(
                      officeName,
                    ),

                  ),

                  ListTile(

                    title: const Text(
                      "Address",
                    ),

                    subtitle: Text(
                      officeAddress,
                    ),

                  ),

                ],

              ),

            ),

          ),

          const SizedBox(height: 20),

          Card(

            child: Padding(

              padding: const EdgeInsets.all(16),

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

                    groupValue: verification,

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

                    groupValue: verification,

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

    builder: (_) => RevenueOpinionStep(

      application: widget.application,

      onBack: () {

        Navigator.pop(context);

      },

      onNext: () {

        Navigator.pop(context);

      },

    ),

  ),

);

await load();

if (mounted) {
  setState(() {});
}

                    },

                  ),

                  RadioListTile<String>(

                    value: "Re-inspect",

                    groupValue: verification,

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

  );

}
}