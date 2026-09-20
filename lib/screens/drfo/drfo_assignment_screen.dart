import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../repositories/user_repository.dart';
import '../../services/session_service.dart';
import '../../services/workflow_service.dart';
import '../../widgets/application_header_card.dart';
import '../../widgets/tpms_app_bar.dart';

class DRFOAssignmentScreen extends StatefulWidget {

  final ApplicationModel application;

  const DRFOAssignmentScreen({

    super.key,

    required this.application,

  });

  @override
  State<DRFOAssignmentScreen> createState() =>
      _DRFOAssignmentScreenState();

}

class _DRFOAssignmentScreenState
    extends State<DRFOAssignmentScreen> {

  final WorkflowService workflowService =
      WorkflowService();

  final UserRepository userRepository =
      UserRepository();

  String inspectionMode = "ASSIGNED_BFO";

  bool saving = false;

  Future<void> continueWorkflow() async {

    if (saving) return;

    setState(() {

      saving = true;

    });

    try {

      if (inspectionMode == "SELF_DRFO") {

        await workflowService.startDRFOSelfInspection(
  applicationId: widget.application.id!,
  officeNumber: widget.application.officeNumber,
  actionBy: SessionService.instance.name,
);


      } else {

        final bfo =
            await userRepository.getBFOByBeat(

          widget.application.beatId!,

        );

        if (bfo == null) {

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(

            const SnackBar(

              content: Text(

                "No active BFO mapped to this Beat.",

              ),

            ),

          );

          setState(() {

            saving = false;

          });

          return;

        }

        await workflowService.assignToBFO(

          applicationId: widget.application.id!,

          assignedBFO: bfo["id"],

          officeNumber: widget.application.officeNumber,

          actionBy: SessionService.instance.name,

        );

      }
            if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(

            inspectionMode == "SELF_DRFO"

                ? "Application marked for DRFO Self Inspection."

                : "Application assigned to Beat BFO successfully.",

          ),

        ),

      );

      Navigator.pop(

        context,

        true,

      );

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text(

            "Error : $e",

          ),

        ),

      );

    }

    if (mounted) {

      setState(() {

        saving = false;

      });

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: const TPMSAppBar(

  title: "DRFO Assignment",

),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            ApplicationHeaderCard(

  application: widget.application,

),

            const SizedBox(height: 25),

            const Text(

              "Choose Inspection Method",

              style: TextStyle(

                fontWeight: FontWeight.bold,

                fontSize: 18,

              ),

            ),

            const SizedBox(height: 15),

            RadioListTile<String>(

              value: "SELF_DRFO",

              groupValue: inspectionMode,

              title: const Text(

                "Self Inspection by DRFO",

              ),

              onChanged: (value) {

                setState(() {

                  inspectionMode = value!;

                });

              },

            ),

            RadioListTile<String>(

              value: "ASSIGNED_BFO",

              groupValue: inspectionMode,

              title: const Text(

                "Assign to Beat BFO",

              ),

              onChanged: (value) {

                setState(() {

                  inspectionMode = value!;

                });

              },

            ),

            const Spacer(),

            Row(

              children: [

                Expanded(

                  child: OutlinedButton(

                    onPressed: saving

                        ? null
                        : () {

                            Navigator.pop(

                              context,

                            );

                          },

                    child: const Text(

                      "CANCEL",

                    ),

                  ),

                ),

                const SizedBox(width: 20),

                Expanded(

                  child: ElevatedButton(

                    onPressed: saving

                        ? null
                        : continueWorkflow,

                    child: saving

                        ? const SizedBox(

                            height: 22,

                            width: 22,

                            child:
                                CircularProgressIndicator(

                              strokeWidth: 2,

                            ),

                          )

                        : const Text(

                            "CONTINUE",

                          ),

                  ),

                ),

              ],

            ),

          ],

        ),

      ),

    );

  }

}