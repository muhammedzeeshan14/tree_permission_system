import 'package:flutter/material.dart';

import '../models/application_model.dart';

class ApplicationHeaderCard extends StatelessWidget {

  final ApplicationModel application;

  const ApplicationHeaderCard({

    super.key,

    required this.application,

  });

  @override
  Widget build(BuildContext context) {

    return Card(

      margin: EdgeInsets.zero,

      elevation: 4,

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

  crossAxisAlignment: CrossAxisAlignment.start,

  children: [

    const Text(

      "Application",

      style: TextStyle(

        fontSize: 18,

        fontWeight: FontWeight.bold,

      ),

    ),

    const Divider(),

    Text(

      "Office No : ${application.officeNumber}",

      style: const TextStyle(

        fontWeight: FontWeight.bold,

        fontSize: 16,

      ),

    ),

    const SizedBox(height: 8),

    Text(

      "Applicant : ${application.applicantName}",

      style: const TextStyle(

        fontSize: 15,

      ),

    ),

  ],

),

      ),

    );

  }

}