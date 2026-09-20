import 'package:flutter/material.dart';

import '../../models/application_model.dart';
import '../../widgets/application_card.dart';

class BFOProgressScreen extends StatelessWidget {

  final ApplicationModel application;

  const BFOProgressScreen({

    super.key,

    required this.application,

  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(

        title: const Text(

          "BFO Progress",

        ),

      ),

      body: ListView(

        padding: const EdgeInsets.all(12),

        children: [

          ApplicationCard(

            application: application,

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

                    "Inspection Status",

                    style: TextStyle(

                      fontWeight: FontWeight.bold,

                      fontSize: 18,

                    ),

                  ),

                  const Divider(),

                  Text(
                    "Inspection Started : ${application.inspectionStarted ? "Yes" : "No"}",
                  ),

                  Text(
                    "Inspection Date : ${application.bfoVerificationDate}",
                  ),

                  Text(
                    "Overall Remarks : ${application.overallRemarks}",
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