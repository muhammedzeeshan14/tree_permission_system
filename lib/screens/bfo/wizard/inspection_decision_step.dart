import 'package:flutter/material.dart';

import '../../../models/application_model.dart';
import '../../../repositories/master_repository.dart';
import '../../../repositories/inspection_defer_reason_repository.dart';
import '../../../widgets/application_header_card.dart';
import '../../../widgets/tpms_app_bar.dart';
import '../../../widgets/wizard_progress_card.dart';

class InspectionDecisionStep extends StatefulWidget {

  final ApplicationModel application;

  final VoidCallback onNext;

  final VoidCallback onBack;

  final VoidCallback onDeferred;

  const InspectionDecisionStep({

    super.key,

    required this.application,

    required this.onNext,

    required this.onBack,

    required this.onDeferred,

  });

  @override
  State<InspectionDecisionStep> createState() =>
      _InspectionDecisionStepState();
}

class _InspectionDecisionStepState
    extends State<InspectionDecisionStep> {

  final MasterRepository repository =
    MasterRepository();

final InspectionDeferredReasonRepository deferredRepository =
    InspectionDeferredReasonRepository();

String? decision;

  List<Map<String, dynamic>> reasons = [];

  List<int?> selectedReasonIds = [null];

  @override
void initState() {
  super.initState();

  decision = widget.application.inspectionDecision.isEmpty
      ? null
      : widget.application.inspectionDecision;

  if (widget.application.deferredReasonIds.isNotEmpty) {
    selectedReasonIds =
        widget.application.deferredReasonIds
            .cast<int?>();
  }

  loadReasons();
}

  Future<void> loadReasons() async {

  reasons = await repository.getMasters(
    "Inspection Deferred Reason",
  );

  if (mounted) {
    setState(() {});
  }

}

  List<Map<String, dynamic>> availableReasons(int index) {

    final alreadySelected = selectedReasonIds
        .asMap()
        .entries
        .where((e) => e.key != index)
        .map((e) => e.value)
        .toSet();

    return reasons.where((item) {

      return !alreadySelected.contains(item["id"]);

    }).toList();

  }

  Future<void> saveDeferredReasons() async {
  if (widget.application.id == null) {
    return;
  }

  final selectedIds =
      selectedReasonIds.whereType<int>().toList();

  final selectedReasons = selectedIds.map((id) {
    return <String, dynamic>{
      "id": id,
    };
  }).toList();

  await deferredRepository.saveReasons(
    applicationId: widget.application.id!,
    reasons: selectedReasons,
  );

  debugPrint(
    "DEFERRED REASONS SAVED: "
    "Application ID = ${widget.application.id}",
  );

  debugPrint(
    "DEFERRED REASON IDS = $selectedIds",
  );
}

  bool validateDeferredReasons() {

    for (final id in selectedReasonIds) {

      if (id != null) {
        return true;
      }

    }

    return false;

  }

  @override
Widget build(BuildContext context) {

  return Scaffold(

    appBar: const TPMSAppBar(
      title: "Inspection Decision",
    ),

    body: SingleChildScrollView(

      padding: const EdgeInsets.all(16),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          ApplicationHeaderCard(
            application: widget.application,
          ),

          const SizedBox(height: 15),

          const WizardProgressCard(
            currentStep: 2,
            totalSteps: 9,
            title: "Inspection Decision",
          ),

          const SizedBox(height: 15),

          Card(

            child: Padding(

              padding: const EdgeInsets.all(20),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  RadioListTile<String>(

                    value: "START",

                    groupValue: decision,

                    title: const Text(
                      "Start Inspection",
                    ),

                    onChanged: (value) {

                      setState(() {

                        decision = value;

                        selectedReasonIds = [null];

                      });

                    },

                  ),

                  RadioListTile<String>(

                    value: "DEFERRED",

                    groupValue: decision,

                    title: const Text(
                      "Inspection Deferred",
                    ),

                    onChanged: (value) {

                      setState(() {

                        decision = value;

                        if (selectedReasonIds.isEmpty) {

                          selectedReasonIds = [null];

                        }

                      });

                    },

                  ),

                  if (decision == "DEFERRED") ...[

                    const SizedBox(height: 20),

                    const Text(

                      "Reasons for Deferring Inspection",

                      style: TextStyle(

                        fontSize: 17,

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                    const SizedBox(height: 15),

                    ...List.generate(

                      selectedReasonIds.length,

                      (index) {

                        return Padding(

                          padding: const EdgeInsets.only(
                            bottom: 15,
                          ),

                          child: Row(

                            crossAxisAlignment:
                                CrossAxisAlignment.start,

                            children: [

                              Expanded(

                                child: DropdownButtonFormField<int>(

                                  value:
                                      selectedReasonIds[index],

                                  decoration:
                                      InputDecoration(

                                    labelText:
                                        "Reason ${index + 1}",

                                    border:
                                        const OutlineInputBorder(),

                                  ),

                                  items:
                                      availableReasons(index)
                                          .map((item) {

                                    return DropdownMenuItem<int>(

                                      value: item["id"],

                                      child: Text(
                                        item["value"],
                                      ),

                                    );

                                  }).toList(),

                                  onChanged: (value) {

                                    setState(() {

                                      selectedReasonIds[index] =
                                          value;

                                    });

                                  },

                                ),

                              ),

                              if (index > 0)

                                IconButton(

                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),

                                  onPressed: () {

                                    setState(() {

                                      selectedReasonIds
                                          .removeAt(index);

                                    });

                                  },

                                ),

                            ],

                          ),

                        );

                      },

                    ),

                    Align(

                      alignment: Alignment.centerLeft,

                      child: TextButton.icon(

                        icon: const Icon(Icons.add),

                        label: const Text(
                          "Add Reason",
                        ),

                        onPressed: () {

                          setState(() {

                            selectedReasonIds.add(null);

                          });

                        },

                      ),

                    ),

                    const SizedBox(height: 20),

                  ],

                                    Row(

                    children: [

                      Expanded(

                        child: ElevatedButton(

                          onPressed: widget.onBack,

                          child: const Text(
                            "BACK",
                          ),

                        ),

                      ),

                      const SizedBox(width: 15),

                      Expanded(

                        child: ElevatedButton(

                          onPressed: () async {

  if (decision == null) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      const SnackBar(

        content: Text(
          "Please select inspection decision.",
        ),

      ),

    );

    return;

  }

  // ==========================================================
  // START INSPECTION
  // ==========================================================

  if (decision == "START") {

    widget.application.inspectionDecision =
        "START";

    widget.application.deferredReasonIds = [];

    // Remove any previously saved deferred reasons.
    if (widget.application.id != null) {
      await deferredRepository.deleteReasons(
        widget.application.id!,
      );
    }

    widget.onNext();

    return;
  }

  // ==========================================================
  // DEFERRED INSPECTION
  // ==========================================================

  if (!validateDeferredReasons()) {

    ScaffoldMessenger.of(context)
        .showSnackBar(

      const SnackBar(

        content: Text(
          "Please select at least one defer reason.",
        ),

      ),

    );

    return;

  }

  widget.application.inspectionDecision =
      "DEFERRED";

  widget.application.deferredReasonIds =
      selectedReasonIds
          .whereType<int>()
          .toList();

  // ==========================================================
  // SAVE DEFERRED REASONS TO DATABASE
  // ==========================================================

  await saveDeferredReasons();

  widget.onDeferred();

},

                          child: const Text(
                            "CONTINUE",
                          ),

                        ),

                      ),

                    ],

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