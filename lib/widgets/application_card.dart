import 'package:flutter/material.dart';

import '../models/application_model.dart';
import 'info_row.dart';
import 'status_chip.dart';

class ApplicationCard extends StatelessWidget {

  final ApplicationModel application;

  final VoidCallback? onTap;

  final Widget? bottomWidget;

  const ApplicationCard({

    super.key,

    required this.application,

    this.onTap,

    this.bottomWidget,

  });

  @override
  Widget build(BuildContext context) {

    return Card(

      elevation: 5,

      margin: const EdgeInsets.only(

        left: 12,
        right: 12,
        top: 8,
        bottom: 8,

      ),

      child: InkWell(

        borderRadius: BorderRadius.circular(12),

        onTap: onTap,

        child: Padding(

          padding: const EdgeInsets.all(16),

          child: Column(

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [

              Row(

                children: [

                  Expanded(

                    child: Text(

                      application.officeNumber,

                      style: const TextStyle(

                        fontSize: 18,

                        fontWeight:
                            FontWeight.bold,

                      ),

                    ),

                  ),

                  StatusChip(

                    status:
                        application.status,

                  ),

                ],

              ),

              const Divider(),

              InfoRow(

                title: "Applicant",

                value:
                    application.applicantName,

              ),

              InfoRow(

                title: "Type",

                value:
                    application.applicationType,

              ),

              InfoRow(

                title: "Section",

                value:
                    application.section,

              ),

              InfoRow(

                title: "Beat",

                value:
                    application.beat,

              ),

              if (application.assignedBFO
                  .isNotEmpty)

                InfoRow(

                  title: "BFO",

                  value:
                      application.assignedBFO,

                ),

              if (application.assignedDRFO
                  .isNotEmpty)

                InfoRow(

                  title: "DRFO",

                  value:
                      application.assignedDRFO,

                ),

              if (bottomWidget != null) ...[

                const SizedBox(height: 12),

                bottomWidget!,

              ],

            ],

          ),

        ),

      ),

    );

  }

}