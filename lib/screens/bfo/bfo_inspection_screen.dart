import 'package:flutter/material.dart';

import '../../models/application_model.dart';

class BFOInspectionScreen extends StatefulWidget {
  final ApplicationModel application;

  const BFOInspectionScreen({
    super.key,
    required this.application,
  });

  @override
  State<BFOInspectionScreen> createState() =>
      _BFOInspectionScreenState();
}

class _BFOInspectionScreenState
    extends State<BFOInspectionScreen> {

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("BFO Inspection"),
        centerTitle: true,
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(16),

        child: Card(

          elevation: 4,

          child: Padding(

            padding: const EdgeInsets.all(20),

            child: Column(

              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                const Text(

                  "Application Details",

                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),

                ),

                const Divider(),

                detail(
                  "Office Number",
                  widget.application.officeNumber,
                ),

                detail(
                  "Applicant",
                  widget.application.applicantName,
                ),

                detail(
                  "Address",
                  widget.application.applicantAddress,
                ),

                detail(
                  "Mobile",
                  widget.application.mobile,
                ),

                detail(
                  "Application Type",
                  widget.application.applicationType,
                ),

                detail(
                  "Purpose",
                  widget.application.purpose,
                ),

                detail(
                  "Section",
                  widget.application.section,
                ),

                detail(
                  "Beat",
                  widget.application.beat,
                ),

                const SizedBox(height:30),

                SizedBox(

                  width: double.infinity,

                  height:55,

                  child: ElevatedButton.icon(

                    icon: const Icon(Icons.play_arrow),

                    label: const Text(

                      "OPEN INSPECTION",

                      style: TextStyle(
                        fontSize:18,
                      ),

                    ),

                    onPressed: () {

                    },

                  ),

                ),

              ],

            ),

          ),

        ),

      ),

    );

  }

  Widget detail(
    String title,
    String value,
  ) {

    return Padding(

      padding:
          const EdgeInsets.symmetric(vertical:8),

      child: Row(

        children: [

          SizedBox(

            width:140,

            child: Text(

              title,

              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),

            ),

          ),

          Expanded(

            child: Text(value),

          ),

        ],

      ),

    );

  }

}