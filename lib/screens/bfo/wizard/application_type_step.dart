import 'package:flutter/material.dart';

import '../../../models/application_model.dart';
import '../../../widgets/responsive_actions.dart';
import '../../../widgets/application_header_card.dart';
import '../../../widgets/tpms_app_bar.dart';
import '../../../widgets/wizard_progress_card.dart';
import '../../../repositories/application_type_repository.dart';
import '../../../repositories/application_type_permission_mapping_repository.dart';

class ApplicationTypeStep extends StatefulWidget {
  final ApplicationModel application;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const ApplicationTypeStep({
    super.key,
    required this.application,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<ApplicationTypeStep> createState() =>
      _ApplicationTypeStepState();
}

class _ApplicationTypeStepState
    extends State<ApplicationTypeStep> {

bool applicationTypeCorrect = true;

String? selectedApplicationType;

List<Map<String, dynamic>> applicationTypes = [];
final mappingRepo =
    ApplicationTypePermissionMappingRepository();

  @override
void initState() {
  super.initState();

  selectedApplicationType = null;

  loadApplicationTypes();
}

Future<void> loadApplicationTypes() async {

  applicationTypes =
      await ApplicationTypeRepository().getActive();

  for (final item in applicationTypes) {

    if (item["shortCode"] ==
            widget.application.applicationType ||
        item["applicationType"] ==
            widget.application.applicationType) {

      selectedApplicationType =
          item["applicationType"];

      break;

    }

  }

  if (mounted) {
    setState(() {});
  }

}

  Future<void> _saveAndContinue() async {

  if (!applicationTypeCorrect &&
      selectedApplicationType == null) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Please select the correct application type.",
        ),
      ),
    );

    return;
  }

  for (final item in applicationTypes) {

  if (item["applicationType"] ==
      selectedApplicationType) {

    widget.application.applicationType =
        item["shortCode"];

    widget.application.verifiedApplicationType =
        item["applicationType"];

    final permission =
        await mappingRepo
            .getPermissionForApplicationType(
                item["id"]);

    widget.application.permissionTypeId =
        permission?["id"];

    widget.application.permissionType =
        permission?["permissionType"] ?? "";

    break;

  }

}

  widget.onNext();
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TPMSAppBar(
       title: "Verify Application Type",
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              ApplicationHeaderCard(
                application: widget.application,
              ),

              const SizedBox(height: 16),

              const WizardProgressCard(
                currentStep: 3,
                totalSteps: 9,
                title: "Verify Application Type",
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                                           const Text(
  "Verify Application Type",
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
),

const SizedBox(height: 20),

const Text(
  "Application Type entered by Case Worker",
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
    border: Border.all(color: Colors.green),
    borderRadius: BorderRadius.circular(8),
  ),
  child: Text(
  selectedApplicationType ?? "",
  style: const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  ),
),
),

const SizedBox(height: 20),

RadioListTile<bool>(
  title: const Text("Correct"),
  value: true,
  groupValue: applicationTypeCorrect,
  onChanged: (value) {
    setState(() {
      applicationTypeCorrect = true;
      // No assignment required.
// selectedApplicationType already contains
// the correct application type name.
    });
  },
),

RadioListTile<bool>(
  title: const Text("Incorrect"),
  value: false,
  groupValue: applicationTypeCorrect,
  onChanged: (value) {
    setState(() {
      applicationTypeCorrect = false;
    });
  },
),

if (!applicationTypeCorrect) ...[
  const SizedBox(height: 15),

  DropdownButtonFormField<String>(
    initialValue: selectedApplicationType,
    decoration: const InputDecoration(
      labelText: "Select Correct Application Type",
      border: OutlineInputBorder(),
    ),
    items: applicationTypes.map((item) {
      return DropdownMenuItem<String>(
        value: item["applicationType"],
        child: Text(item["applicationType"]),
      );
    }).toList(),
    onChanged: (value) {
      setState(() {
        selectedApplicationType = value;
      });
    },
  ),
],

const SizedBox(height: 30),

                      ResponsiveActions(
                        children: [
                          ElevatedButton(
                            onPressed: widget.onBack,
                            child: const Text(
                              "BACK",
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _saveAndContinue,
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
            ],
          ),
        ),
      ),
    );
  }
}