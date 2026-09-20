import 'package:flutter/material.dart';

class DashboardHeader extends StatelessWidget {

  final String title;
  final String officerName;
  final String designation;
  final String rangeName;

  const DashboardHeader({

    super.key,

    required this.title,

    required this.officerName,

    required this.designation,

    required this.rangeName,

  });

  @override
  Widget build(BuildContext context) {

    return Card(

      elevation: 4,

      margin: const EdgeInsets.all(12),

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Text(

              title,

              style: const TextStyle(

                fontSize: 22,

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 8),

            Text(

              "Range Forest Office, $rangeName",

            ),

            const Divider(),

            Text(

              officerName,

              style: const TextStyle(

                fontSize: 18,

                fontWeight: FontWeight.bold,

              ),

            ),

            Text(designation),

          ],

        ),

      ),

    );

  }

}