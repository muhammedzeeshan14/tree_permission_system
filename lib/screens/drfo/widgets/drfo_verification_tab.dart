import 'package:flutter/material.dart';

import '../../../models/application_model.dart';
import '../../../widgets/application_card.dart';

class DRFOVerificationTab extends StatelessWidget {

  final List<ApplicationModel> applications;

  final Function(ApplicationModel) onOpen;

  const DRFOVerificationTab({

    super.key,

    required this.applications,

    required this.onOpen,

  });

  @override
  Widget build(BuildContext context) {

    if (applications.isEmpty) {

      return const Center(

        child: Text(
          "No Applications Pending Verification",
        ),

      );

    }

    return ListView.builder(

      itemCount: applications.length,

      itemBuilder: (context, index) {

        final app = applications[index];

        return ApplicationCard(

          application: app,

          bottomWidget: SizedBox(

            width: double.infinity,

            child: ElevatedButton(

              onPressed: () {

                onOpen(app);

              },

              child: const Text(
                "OPEN VERIFICATION",
              ),

            ),

          ),

        );

      },

    );

  }

}