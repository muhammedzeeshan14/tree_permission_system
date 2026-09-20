import 'package:flutter/material.dart';

class WizardProgressCard extends StatelessWidget {

  final int currentStep;
  final int totalSteps;
  final String title;

  const WizardProgressCard({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
  });

  @override
Widget build(BuildContext context) {

  final progress = currentStep / totalSteps;

  return Card(

    elevation: 2,

    margin: EdgeInsets.zero,

    child: Padding(

      padding: const EdgeInsets.symmetric(

        horizontal: 16,

        vertical: 12,

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Row(

            children: [

              Text(

                "Step $currentStep of $totalSteps",

                style: const TextStyle(

                  fontWeight: FontWeight.bold,

                ),

              ),

              const SizedBox(width: 10),

              Expanded(

                child: Text(

                  title,

                  style: const TextStyle(

                    fontWeight: FontWeight.bold,

                    fontSize: 16,

                  ),

                ),

              ),

            ],

          ),

          const SizedBox(height: 8),

          LinearProgressIndicator(

            value: progress,

          ),

        ],

      ),

    ),

  );

}

}