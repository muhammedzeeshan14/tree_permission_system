import 'package:flutter/material.dart';

import '../../models/application_model.dart';

class GenerateDocumentsScreen extends StatelessWidget {
  final ApplicationModel application;

  final VoidCallback onBack;
  final VoidCallback onSaveDraft;
  final VoidCallback onForward;

  const GenerateDocumentsScreen({
    super.key,
    required this.application,
    required this.onBack,
    required this.onSaveDraft,
    required this.onForward,
  });

  // ==========================================================
  // APPLICATION TYPE
  // ==========================================================

  bool get isRtcApplication {
    return application.applicationType.trim().toUpperCase() == 'RTC';
  }

  bool get isNonRtcApplication {
    return !isRtcApplication;
  }

  // ==========================================================
  // INSPECTION STATUS
  // ==========================================================

  bool get isDeferredInspection {
    return application.inspectionDecision.trim().toUpperCase() ==
        'DEFERRED';
  }

  bool get isCompletedInspection {
    return !isDeferredInspection &&
        application.drfoInspectionDate.isNotEmpty;
  }

  // ==========================================================
  // DOCUMENT DESCRIPTION
  // ==========================================================

  String get documentDescription {
    if (isRtcApplication && isDeferredInspection) {
  return 'Inspection deferred.\n\n'
      'DRFO RTC Deferred Letter will be generated automatically '
      'when the application is forwarded to RFO.';
}

if (isRtcApplication && isCompletedInspection) {
  return 'Inspection completed.\n\n'
      'DRFO RTC Recommended Letter will be generated automatically '
      'when the application is forwarded to RFO.';
}

if (isRtcApplication) {
  return 'RTC application documents are handled separately.';
}

    if (isDeferredInspection) {
      return 'Inspection deferred.\n\n'
          'DRFO Deferred Letter will be generated automatically '
          'when the application is forwarded to RFO.';
    }

    if (isCompletedInspection) {
      return 'Inspection completed.\n\n'
          'The following documents will be generated automatically '
          'when the application is forwarded to RFO:\n\n'
          '• DRFO Recommended Letter\n'
          '• Mahazar — if available\n'
          '• Tree Enumeration List — if available';
    }

    return 'Inspection status is not yet ready for document generation.';
  }

  // ==========================================================
  // DOCUMENT LIST
  // ==========================================================

  List<String> get documentsToBeGenerated {
    if (isRtcApplication && isDeferredInspection) {
  return [
    'DRFO RTC Deferred Letter',
  ];
}

if (isRtcApplication && isCompletedInspection) {
  return [
    'DRFO RTC Recommended Letter',
  ];
}

if (isRtcApplication) {
  return [];
}

    if (isDeferredInspection) {
      return [
        'DRFO Deferred Letter',
      ];
    }

    if (isCompletedInspection) {
      return [
        'DRFO Recommended Letter',
        'Mahazar — if available',
        'Tree Enumeration List — if available',
      ];
    }

    return [];
  }

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final bool ready =
    isDeferredInspection || isCompletedInspection;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),

              child: Column(
                children: [
                  Icon(
                    isDeferredInspection
                        ? Icons.schedule
                        : isCompletedInspection
                            ? Icons.check_circle_outline
                            : Icons.description_outlined,
                    size: 70,
                    color: isDeferredInspection
                        ? Colors.orange
                        : Colors.green,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'DRFO Documents',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  Text(
                    application.officeNumber,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 25),

                  Text(
                    documentDescription,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: ready
                          ? Colors.black87
                          : Colors.grey.shade700,
                    ),
                  ),

                  if (documentsToBeGenerated.isNotEmpty) ...[
                    const SizedBox(height: 25),

                    Align(
                      alignment: Alignment.centerLeft,

                      child: Text(
                        'Documents:',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    ...documentsToBeGenerated.map(
                      (document) => Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 5,
                        ),

                        child: Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [
                            const Icon(
                              Icons.picture_as_pdf,
                              size: 20,
                              color: Colors.green,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                document,
                                style: const TextStyle(
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 25),

                  if (ready)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),

                      decoration: BoxDecoration(
                        color: Colors.green.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius:
                            BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.green.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),

                      child: const Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.green,
                          ),

                          SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              'No document needs to be selected manually. '
                              'The appropriate documents will be generated '
                              'automatically when the application is forwarded '
                              'to the RFO.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
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