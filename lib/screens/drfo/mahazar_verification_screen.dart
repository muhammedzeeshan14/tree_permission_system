import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../models/mahazar_model.dart';

import '../../repositories/mahazar_repository.dart';
import '../../repositories/mahazar_verification_repository.dart';
import '../../repositories/master_repository.dart';

import '../bfo/wizard/mahazar_step.dart';

class MahazarVerificationScreen extends StatefulWidget {

  final ApplicationModel application;

  const MahazarVerificationScreen({

    super.key,

    required this.application,

  });

  @override
  State<MahazarVerificationScreen> createState() =>
      MahazarVerificationScreenState();

}

class MahazarVerificationScreenState
    extends State<MahazarVerificationScreen> {

  final mahazarRepository =
      MahazarRepository();

  final verificationRepository =
      MahazarVerificationRepository();

  final masterRepository =
      MasterRepository();

  MahazarModel? mahazar;
  String northDisplay = "";
String eastDisplay = "";
String southDisplay = "";
String westDisplay = "";

  String? verification;

  List<String> reasons = [];

  @override
  void initState() {

    super.initState();

    load();

  }

  Future<void> load() async {

    mahazar =
        await mahazarRepository.getByApplication(
      widget.application.id!,
    );

if (mahazar != null) {
  Future<String> boundaryDisplay(
    int? locationId,
    String additionalText,
  ) async {
    final master =
        await masterRepository.getMasterById(
      locationId,
    );

     final location =
        master?["value"]?.toString().trim() ?? "";

    final details = additionalText.trim();

    if (location.isNotEmpty &&
        details.isNotEmpty) {
      return "$location - $details";
    }

    if (location.isNotEmpty) {
      return location;
    }

    return details;
  }

  northDisplay = await boundaryDisplay(
    mahazar!.northLocationId,
    mahazar!.northBoundary,
  );

  eastDisplay = await boundaryDisplay(
    mahazar!.eastLocationId,
    mahazar!.eastBoundary,
  );

  southDisplay = await boundaryDisplay(
    mahazar!.southLocationId,
    mahazar!.southBoundary,
  );

  westDisplay = await boundaryDisplay(
    mahazar!.westLocationId,
    mahazar!.westBoundary,
  );
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

String get mahazarDateDisplay {
  final value = mahazar?.mahazarDate ?? "";

  final date = DateTime.tryParse(value);

  if (date == null) return value;

  return "${date.day.toString().padLeft(2, "0")}/"
      "${date.month.toString().padLeft(2, "0")}/"
      "${date.year}";
}

String get startTimeDisplay {
  final manual =
      mahazar?.startTimeManual.trim() ?? "";

  if (manual.isNotEmpty) return manual;

  return mahazar?.startTime ?? "";
}

String get endTimeDisplay {
  final manual =
      mahazar?.endTimeManual.trim() ?? "";

  if (manual.isNotEmpty) return manual;

  return mahazar?.endTime ?? "";
}

  bool validateVerification() {

    if (verification == null) {

      ScaffoldMessenger.of(context)
          .showSnackBar(

        const SnackBar(

          content: Text(
            "Please verify Mahazar.",
          ),

        ),

      );

      return false;

    }

    return true;

  }

  Future<String?> showReinspectDialog() async {

  String? selectedReason;

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

          initialValue: selectedReason,

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

                    "Mahazar Details",

                    style: TextStyle(

                      fontSize: 18,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                  const Divider(),

                  ListTile(

                    title:
                        const Text("Mahazar Date"),

                    subtitle: Text(

                      mahazarDateDisplay,

                    ),

                  ),

ListTile(
  title: const Text("Starting Time"),
  subtitle: Text(startTimeDisplay),
),

ListTile(
  title: const Text("Ending Time"),
  subtitle: Text(endTimeDisplay),
),

                  ListTile(

                    title:
                        const Text("North"),

                    subtitle: Text(

                      northDisplay,

                    ),

                  ),

                  ListTile(

                    title:
                        const Text("East"),

                    subtitle: Text(

                      eastDisplay,

                    ),

                  ),

                  ListTile(

                    title:
                        const Text("South"),

                    subtitle: Text(

                      southDisplay,

                    ),

                  ),

                  ListTile(

                    title:
                        const Text("West"),

                    subtitle: Text(

                      westDisplay,

                    ),

                  ),

                ],

              ),

            ),

          ),

          const SizedBox(height:20),

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

                      fontSize:18,

                      fontWeight:
                          FontWeight.bold,

                    ),

                  ),

                  const Divider(),

                  RadioListTile<String>(

                    value:"Correct",

                    groupValue:
                        verification,

                    title:
                        const Text("Correct"),

                    onChanged:(v) async {

                      verification=v;

                      setState((){});

                      await verificationRepository
                          .saveVerification(

                        applicationId:
                            widget.application.id!,

                        verification:v!,

                      );

                    },

                  ),

                  RadioListTile<String>(

                    value:"Modify",

                    groupValue:
                        verification,

                    title:
                        const Text("Modify"),

                    onChanged:(v) async {

                      verification=v;

                      setState((){});

                      await verificationRepository
                          .saveVerification(

                        applicationId:
                            widget.application.id!,

                        verification:v!,

                      );

                      await Navigator.push(

                        context,

                        MaterialPageRoute(

                          builder: (_) => MahazarStep(

                            application:
                                widget.application,

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

                    },

                  ),

                  RadioListTile<String>(

                    value:"Re-inspect",

                    groupValue:
                        verification,

                    title:
                        const Text(
                          "Re-inspect",
                        ),

                    onChanged:(v) async {

                      final previous = verification;

                      verification=v;

                      setState((){});

                      final reason =
                          await showReinspectDialog();

                      if (reason == null) {
                        verification = previous;

                        setState((){});
                        return;
                      }

                      await verificationRepository
                          .saveVerification(

                        applicationId:
                            widget.application.id!,

                        verification:v!,

                        reason: reason,

                      );

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