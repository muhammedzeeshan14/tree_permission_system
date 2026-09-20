import 'package:flutter/material.dart';

import '../models/application_model.dart';

class VerificationHeader extends StatelessWidget {

  final ApplicationModel application;

  const VerificationHeader({

    super.key,

    required this.application,

  });

  @override
  Widget build(BuildContext context) {

    return Container(

      width: double.infinity,

      color: Colors.green.shade50,

      padding: const EdgeInsets.all(12),

      child: Column(

        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          Text(

            application.officeNumber,

            style: const TextStyle(

              fontWeight: FontWeight.bold,

              fontSize: 18,

            ),

          ),

          const SizedBox(height: 5),

          Text(
            "Applicant : ${application.applicantName}",
          ),

          Text(
            "Application Type : ${application.applicationType}",
          ),

          Text(
            "Section : ${application.section}",
          ),

          Text(
            "Beat : ${application.beat}",
          ),

        ],

      ),

    );

  }

}