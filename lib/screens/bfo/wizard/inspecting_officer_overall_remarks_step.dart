import 'package:flutter/material.dart';

import '../../../models/application_model.dart';
import '../../../repositories/application_repository.dart';
import '../../../repositories/master_repository.dart';
import '../../../widgets/application_header_card.dart';
import '../../../widgets/tpms_app_bar.dart';
import '../../../widgets/wizard_progress_card.dart';

class InspectingOfficerOverallRemarksStep
    extends StatefulWidget {
  final ApplicationModel application;

  final VoidCallback onBack;

  final VoidCallback onNext;

  const InspectingOfficerOverallRemarksStep({
    super.key,
    required this.application,
    required this.onBack,
    required this.onNext,
  });

  @override
  State<InspectingOfficerOverallRemarksStep>
      createState() =>
          _InspectingOfficerOverallRemarksStepState();
}

class _InspectingOfficerOverallRemarksStepState
    extends State<
        InspectingOfficerOverallRemarksStep> {
  final MasterRepository masterRepository =
      MasterRepository();

  final ApplicationRepository
      applicationRepository =
      ApplicationRepository();

  List<Map<String, dynamic>> remarks = [];

  int? selectedRemarkId;

  bool loading = true;

  bool saving = false;

  @override
  void initState() {
    super.initState();

    selectedRemarkId =
        widget.application.overallRemarkId;

    loadRemarks();
  }

  Future<void> loadRemarks() async {
    final allRemarks =
        await masterRepository.getMasters(
      "Inspecting Officer Overall Remark",
    );

    remarks = allRemarks.where((item) {
      final isActive = item["isActive"] == 1;

      final isCurrentlySelected =
          item["id"] == selectedRemarkId;

      return isActive || isCurrentlySelected;
    }).toList();

    final selectedStillExists = remarks.any(
      (item) => item["id"] == selectedRemarkId,
    );

    if (!selectedStillExists) {
      selectedRemarkId = null;
    }

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> saveAndContinue() async {
    if (selectedRemarkId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please select the inspecting officer's overall remarks.",
          ),
        ),
      );

      return;
    }

    final selectedItem = remarks.firstWhere(
      (item) => item["id"] == selectedRemarkId,
    );

    final englishValue =
        selectedItem["value"]
                ?.toString()
                .trim() ??
            "";

    if (englishValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "The selected overall remark has no English value.",
          ),
        ),
      );

      return;
    }

    setState(() {
      saving = true;
    });

    widget.application.overallRemarkId =
        selectedRemarkId;

    // English is stored for display and old screens.
    // Kannada remains in the master for documents.
    widget.application.overallRemarks =
        englishValue;

    await applicationRepository.updateApplication(
      widget.application,
    );

    if (!mounted) return;

    setState(() {
      saving = false;
    });

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TPMSAppBar(
        title: "Inspecting Officer's Overall Remarks",
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  ApplicationHeaderCard(
                    application: widget.application,
                  ),
                  const SizedBox(height: 15),
                  const WizardProgressCard(
                    currentStep: 9,
                    totalSteps: 13,
                    title:
                        "Inspecting Officer's Overall Remarks",
                  ),
                  const SizedBox(height: 15),
                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(20),
                      child:
                          DropdownButtonFormField<int>(
                        value: selectedRemarkId,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(
                          labelText:
                              "Overall Remarks",
                          border:
                              OutlineInputBorder(),
                        ),
                       items: remarks.map((item) {
  return DropdownMenuItem<int>(
    value: item["id"] as int?,
    child: Text(
      item["value"]?.toString() ?? "",
    ),
  );
}).toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                                setState(() {
                                  selectedRemarkId =
                                      value;
                                });
                              },
                      ),
                    ),
                  ),
                  if (remarks.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(
                        top: 12,
                      ),
                      child: Text(
                        "No active overall remarks are available. "
                        "Please add them in RFO Masters.",
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              saving
                                  ? null
                                  : widget.onBack,
                          child: const Text("BACK"),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                              saving || remarks.isEmpty
                                  ? null
                                  : saveAndContinue,
                          child: saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("CONTINUE"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}