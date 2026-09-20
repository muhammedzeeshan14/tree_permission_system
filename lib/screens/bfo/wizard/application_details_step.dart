import 'package:flutter/material.dart';

import '../../../models/application_model.dart';
import '../../../widgets/tpms_app_bar.dart';
import '../../../widgets/application_header_card.dart';
import '../../../widgets/wizard_progress_card.dart';

class ApplicationDetailsStep extends StatelessWidget {

  final ApplicationModel application;

  final VoidCallback onNext;

  const ApplicationDetailsStep({

    super.key,

    required this.application,

    required this.onNext,

  });

  Widget detail(
  String title,
  String value,
) {

  return Padding(

    padding: const EdgeInsets.symmetric(vertical: 4),

    child: Row(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        SizedBox(

          width: 160,

          child: Text(

            title,

            style: const TextStyle(

              fontWeight: FontWeight.w600,

            ),

          ),

        ),

        Expanded(

          child: Text(

            value.isEmpty ? "-" : value,

          ),

        ),

      ],

    ),

  );

}

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: const TPMSAppBar(

  title: "BFO Inspection",

),

      body: SingleChildScrollView(

  padding: const EdgeInsets.all(16),

  child: Column(

    crossAxisAlignment: CrossAxisAlignment.start,

    children: [

      ApplicationHeaderCard(

        application: application,

      ),

      const SizedBox(height: 15),

      const WizardProgressCard(

        currentStep: 1,

        totalSteps: 9,

        title: "Application Details",

      ),

      const SizedBox(height: 15),

      Card(

          child: Padding(

            padding: const EdgeInsets.all(20),

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const Text(

  "Application Details",

  style: TextStyle(

    fontSize: 20,

    fontWeight: FontWeight.bold,

  ),

),

                const Divider(),

                detail(
                    "Office No",
                    application.officeNumber),

                detail(
                    "Applicant",
                    application.applicantName),

                detail(
                    "Address",
                    application.applicantAddress),

                detail(
                    "Mobile",
                    application.mobile),

                detail(
                    "Application Type",
                    application.applicationType),

                detail(
                    "Purpose",
                    application.purpose),

                detail(
                    "Section",
                    application.section),

                detail(
                    "Beat",
                    application.beat),

                const SizedBox(height:20),

                SizedBox(

                  width: double.infinity,

                  height:55,

                  child: ElevatedButton.icon(

                    icon: const Icon(Icons.arrow_forward),

                    label: const Text(

                      "OPEN INSPECTION",

                      style: TextStyle(
                        fontSize:18,
                      ),

                    ),

                    onPressed: onNext,

                  ),

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