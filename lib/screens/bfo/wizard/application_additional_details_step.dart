import 'package:flutter/material.dart';

import '../../../models/application_model.dart';
import '../../../widgets/responsive_actions.dart';
import '../../../repositories/master_repository.dart';
import '../../../widgets/application_header_card.dart';
import '../../../widgets/tpms_app_bar.dart';
import '../../../widgets/wizard_progress_card.dart';

class ApplicationAdditionalDetailsStep
    extends StatefulWidget {
  final ApplicationModel application;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ApplicationAdditionalDetailsStep({
    super.key,
    required this.application,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<ApplicationAdditionalDetailsStep>
      createState() =>
          _ApplicationAdditionalDetailsStepState();
}

class _ApplicationAdditionalDetailsStepState
    extends State<ApplicationAdditionalDetailsStep> {
  final workNameController = TextEditingController();

   List<Map<String, dynamic>> governmentAgencyList = [];
  List<Map<String, dynamic>> urbanRuralList = [];
  List<Map<String, dynamic>> whyRemovingList = [];
  List<Map<String, dynamic>> allPurposeList = [];
  List<Map<String, dynamic>> purposeList = [];
  List<Map<String, dynamic>> structureTypeList = [];

    int? selectedGovernmentAgencyId;
  int? selectedUrbanRuralId;
  int? selectedWhyRemovingId;
  int? selectedPurposeId;
  int? selectedStructureTypeId;

    bool firstFieldCorrect = true;
  bool whyRemovingCorrect = true;
  bool purposeCorrect = true;
  bool structureTypeCorrect = true;
  bool workNameCorrect = true;

  bool loading = true;

  String get applicationType =>
      widget.application.applicationType
          .trim()
          .toUpperCase();

  bool get isMcc => applicationType == "MCC";

  bool get isGovernmentCategory =>
      applicationType == "GL" ||
      applicationType == "STGL" ||
      applicationType == "CGL" ||
      applicationType == "SGL" ||
      applicationType == "MCC";

  bool get showsGovernmentAgency =>
      isGovernmentCategory && !isMcc;

  bool get isPrivateCategory =>
      applicationType == "PL" ||
      applicationType == "SPL";

    String get selectedWhyRemovingCode {
    if (selectedWhyRemovingId == null) {
      return "";
    }

    final matches = whyRemovingList.where(
      (item) =>
          item["id"] ==
          selectedWhyRemovingId,
    );

    if (matches.isEmpty) return "";

    return matches.first["code"]
            ?.toString()
            .trim()
            .toUpperCase() ??
        "";
  }

  bool get isDevelopmentWork =>
      selectedWhyRemovingCode == "WORKS";

  @override
  void initState() {
    super.initState();

    selectedGovernmentAgencyId =
        widget.application.governmentAgencyId;

     selectedUrbanRuralId =
        widget.application.urbanRuralId;

    selectedWhyRemovingId =
        widget.application.whyRemovingId;

    selectedPurposeId =
        widget.application.purposeId;

    selectedStructureTypeId =
        widget.application.structureTypeId;
    workNameController.text =
        widget.application.workName;

    firstFieldCorrect = showsGovernmentAgency
        ? selectedGovernmentAgencyId != null
        : isMcc
            ? true
            : selectedUrbanRuralId != null;

    whyRemovingCorrect =
        selectedWhyRemovingId != null;

    purposeCorrect =
        selectedPurposeId != null ||
            widget.application.purpose.trim().isNotEmpty;

    structureTypeCorrect =
        selectedStructureTypeId != null;

    workNameCorrect =
        workNameController.text.trim().isNotEmpty;

    loadMasters();
  }

  void filterPurposeList() {
    final parentCode =
        selectedWhyRemovingCode;

    if (parentCode.isEmpty) {
      purposeList = [];
      return;
    }

    purposeList = allPurposeList.where((item) {
      final purposeParentCode =
          item["parentCode"]
                  ?.toString()
                  .trim()
                  .toUpperCase() ??
              "";

      return purposeParentCode ==
          parentCode;
    }).toList();

    final selectedPurposeStillValid =
        purposeList.any(
      (item) =>
          item["id"] ==
          selectedPurposeId,
    );

    if (!selectedPurposeStillValid) {
      selectedPurposeId = null;
    }
  }

  Future<void> loadMasters() async {
    final repository = MasterRepository();

    final agencies =
        await repository.getMasters(
      "Government Agency",
    );

    final urbanRural =
        await repository.getMasters(
      "Urban Rural",
    );

    final whyRemoving =
        await repository.getMasters(
      "Why Removing",
    );

    final purposes =
        await repository.getMasters(
      "Purpose",
    );

    final structureTypes =
        await repository.getMasters(
      "Structure Type",
    );

    governmentAgencyList =
        _activeOrSelected(
      agencies,
      selectedGovernmentAgencyId,
    );

    urbanRuralList =
        _activeOrSelected(
      urbanRural,
      selectedUrbanRuralId,
    );

    whyRemovingList =
        _activeOrSelected(
      whyRemoving,
      selectedWhyRemovingId,
    );

     allPurposeList =
        _activeOrSelected(
      purposes,
      selectedPurposeId,
    );

    filterPurposeList();

    structureTypeList =
        _activeOrSelected(
      structureTypes,
      selectedStructureTypeId,
    );

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _activeOrSelected(
    List<Map<String, dynamic>> items,
    int? selectedId,
  ) {
    return items.where((item) {
      return item["isActive"] == 1 ||
          item["id"] == selectedId;
    }).toList();
  }

   String _masterName(
    List<Map<String, dynamic>> items,
    int? id,
  ) {
    if (id == null) return "";

    final matches =
        items.where((item) => item["id"] == id);

    if (matches.isEmpty) return "";

    final item = matches.first;

    // Show English only during application operation.
    // Kannada remains stored in the master for documents.
    return item["value"]?.toString().trim() ?? "";
  }

  List<DropdownMenuItem<int>> _masterItems(
    List<Map<String, dynamic>> items,
  ) {
    return items.map((item) {
      return DropdownMenuItem<int>(
        value: item["id"] as int,
        child: Text(
          item["value"]?.toString().trim() ?? "",
        ),
      );
    }).toList();
  }

  Widget _verificationCard({
    required String title,
    required String enteredValue,
    required bool isCorrect,
    required ValueChanged<bool> onCorrectChanged,
    required Widget correctionField,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              "Entered by Case Worker",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(
                  color: Colors.green,
                ),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Text(
                enteredValue.isEmpty
                    ? "Not entered"
                    : enteredValue,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 12),

            RadioListTile<bool>(
              title: const Text("Correct"),
              value: true,
              groupValue: isCorrect,
              onChanged: (value) {
                if (value != null) {
                  onCorrectChanged(value);
                }
              },
            ),

            RadioListTile<bool>(
              title: const Text("Incorrect"),
              value: false,
              groupValue: isCorrect,
              onChanged: (value) {
                if (value != null) {
                  onCorrectChanged(value);
                }
              },
            ),

            if (!isCorrect) ...[
              const SizedBox(height: 12),
              correctionField,
            ],
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  void _saveAndContinue() {
    if (showsGovernmentAgency &&
        selectedGovernmentAgencyId == null) {
      _showMessage(
        "Please select the correct Government Agency.",
      );
      return;
    }

    if (isPrivateCategory &&
        selectedUrbanRuralId == null) {
      _showMessage(
        "Please select the correct Urban / Rural.",
      );
      return;
    }

    if (selectedWhyRemovingId == null) {
      _showMessage(
        "Please select the correct Why Removing.",
      );
      return;
    }

    if (selectedPurposeId == null) {
      _showMessage(
        "Please select the correct Purpose.",
      );
      return;
    }

    if (selectedStructureTypeId == null) {
      _showMessage(
        "Please select the correct Structure Type.",
      );
      return;
    }

    if (isDevelopmentWork &&
        workNameController.text.trim().isEmpty) {
      _showMessage(
        "Please enter the correct Name of Work.",
      );
      return;
    }

    if (showsGovernmentAgency) {
      widget.application.governmentAgencyId =
          selectedGovernmentAgencyId;

      widget.application.urbanRuralId = null;
    } else {
      widget.application.governmentAgencyId = null;
    }

    if (isPrivateCategory) {
      widget.application.urbanRuralId =
          selectedUrbanRuralId;

      widget.application.governmentAgencyId = null;
    }

    widget.application.whyRemovingId =
        selectedWhyRemovingId;

    widget.application.purposeId =
        selectedPurposeId;

    final selectedPurpose =
        purposeList.firstWhere(
      (item) => item["id"] == selectedPurposeId,
    );

    // Keep the English purpose text for compatibility
    // with existing screens and document generation.
    widget.application.purpose =
        selectedPurpose["value"]?.toString() ?? "";

    widget.application.structureTypeId =
        selectedStructureTypeId;

    widget.application.workName =
        isDevelopmentWork
            ? workNameController.text.trim()
            : "";

    widget.onNext();
  }

  @override
  void dispose() {
    workNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstTitle = isGovernmentCategory
        ? "Government Agency"
        : "Urban / Rural";

    final firstValue = isGovernmentCategory
        ? _masterName(
            governmentAgencyList,
            widget.application.governmentAgencyId,
          )
        : _masterName(
            urbanRuralList,
            widget.application.urbanRuralId,
          );

    return Scaffold(
      appBar: const TPMSAppBar(
        title: "Verify Application Details",
      ),
      body: SafeArea(
        child: loading
            ? const Center(
                child:
                    CircularProgressIndicator(),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    ApplicationHeaderCard(
                      application:
                          widget.application,
                    ),

                    const SizedBox(height: 16),

                    const WizardProgressCard(
                      currentStep: 4,
                      totalSteps: 12,
                      title:
                          "Verify Application Details",
                    ),

                    const SizedBox(height: 16),

                    // MCC has neither agency nor urban/rural selection.
                    if (!isMcc)
                    _verificationCard(
                      title: firstTitle,
                      enteredValue: firstValue,
                      isCorrect:
                          firstFieldCorrect,
                      onCorrectChanged: (value) {
                        setState(() {
                          firstFieldCorrect = value;
                        });
                      },
                      correctionField:
                          DropdownButtonFormField<int>(
                        initialValue: isGovernmentCategory
                            ? selectedGovernmentAgencyId
                            : selectedUrbanRuralId,
                        decoration: InputDecoration(
                          labelText:
                              "Select Correct $firstTitle",
                          border:
                              const OutlineInputBorder(),
                        ),
                        items: isGovernmentCategory
                            ? _masterItems(
                                governmentAgencyList,
                              )
                            : _masterItems(
                                urbanRuralList,
                              ),
                        onChanged: (value) {
                          setState(() {
                            if (isGovernmentCategory) {
                              selectedGovernmentAgencyId =
                                  value;
                            } else {
                              selectedUrbanRuralId =
                                  value;
                            }
                          });
                        },
                      ),
                    ),

                    _verificationCard(
                      title: "Why Removing",
                      enteredValue: _masterName(
                        whyRemovingList,
                        widget.application
                            .whyRemovingId,
                      ),
                      isCorrect:
                          whyRemovingCorrect,
                      onCorrectChanged: (value) {
                        setState(() {
                          whyRemovingCorrect =
                              value;
                        });
                      },
                      correctionField:
                          DropdownButtonFormField<int>(
                        initialValue:
                            selectedWhyRemovingId,
                        decoration:
                            const InputDecoration(
                          labelText:
                              "Select Correct Why Removing",
                          border:
                              OutlineInputBorder(),
                        ),
                        items: _masterItems(
                          whyRemovingList,
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedWhyRemovingId =
                                value;

                            filterPurposeList();

                            if (!isDevelopmentWork) {
                              workNameController
                                  .clear();
                            }
                          });
                        },
                      ),
                    ),

                    _verificationCard(
                      title: "Purpose",
                      enteredValue: _masterName(
                        purposeList,
                        widget.application.purposeId,
                      ).isNotEmpty
                          ? _masterName(
                              purposeList,
                              widget.application
                                  .purposeId,
                            )
                          : widget
                              .application.purpose,
                      isCorrect:
                          purposeCorrect,
                      onCorrectChanged: (value) {
                        setState(() {
                          purposeCorrect = value;
                        });
                      },
                      correctionField:
                          DropdownButtonFormField<int>(
                        initialValue: selectedPurposeId,
                        decoration:
                            const InputDecoration(
                          labelText:
                              "Select Correct Purpose",
                          border:
                              OutlineInputBorder(),
                        ),
                        items: _masterItems(
                          purposeList,
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedPurposeId =
                                value;
                          });
                        },
                      ),
                    ),

                    _verificationCard(
                      title: "Structure Type",
                      enteredValue: _masterName(
                        structureTypeList,
                        widget.application
                            .structureTypeId,
                      ),
                      isCorrect:
                          structureTypeCorrect,
                      onCorrectChanged: (value) {
                        setState(() {
                          structureTypeCorrect = value;
                        });
                      },
                      correctionField:
                          DropdownButtonFormField<int>(
                        initialValue:
                            selectedStructureTypeId,
                        decoration:
                            const InputDecoration(
                          labelText:
                              "Select Correct Structure Type",
                          border:
                              OutlineInputBorder(),
                        ),
                        items: _masterItems(
                          structureTypeList,
                        ),
                        onChanged: (value) {
                          setState(() {
                            selectedStructureTypeId =
                                value;
                          });
                        },
                      ),
                    ),

                                       if (isDevelopmentWork)
                    _verificationCard(
                      title: "Name of Work",
                      enteredValue:
                          widget.application.workName,
                      isCorrect: workNameCorrect,
                      onCorrectChanged: (value) {
                        setState(() {
                          workNameCorrect = value;
                        });
                      },
                      correctionField:
                          TextFormField(
                        controller:
                            workNameController,
                        decoration:
                            const InputDecoration(
                          labelText:
                              "Enter Correct Name of Work",
                          border:
                              OutlineInputBorder(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    ResponsiveActions(
                      children: [
                        ElevatedButton(
                          onPressed: widget.onBack,
                          child:
                              const Text("BACK"),
                        ),
                        ElevatedButton(
                          onPressed:
                              _saveAndContinue,
                          child: const Text(
                            "SAVE & CONTINUE",
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}