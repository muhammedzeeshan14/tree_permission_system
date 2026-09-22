import 'package:flutter/material.dart';

import '../../../widgets/responsive_actions.dart';
import '../../../models/application_model.dart';

import '../../../widgets/application_header_card.dart';
import '../../../widgets/tpms_app_bar.dart';
import '../../../widgets/wizard_progress_card.dart';

class GPSStep extends StatefulWidget {
  final ApplicationModel application;

  final VoidCallback onNext;

  final VoidCallback onBack;

  const GPSStep({
    super.key,
    required this.application,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<GPSStep> createState() => _GPSStepState();
}

class _GPSStepState extends State<GPSStep> {
  late final TextEditingController latitudeController;

  late final TextEditingController longitudeController;

  @override
  void initState() {
    super.initState();

    latitudeController = TextEditingController();
    longitudeController = TextEditingController();

    if (widget.application.gpsCoordinates.isNotEmpty) {
      final parts =
          widget.application.gpsCoordinates.split(",");

      if (parts.length == 2) {
        latitudeController.text = parts[0].trim();
        longitudeController.text = parts[1].trim();
      }
    }
  }

  @override
  void dispose() {
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  void _saveAndContinue() {
    if (latitudeController.text.trim().isEmpty ||
        longitudeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please enter GPS coordinates.",
          ),
        ),
      );
      return;
    }

    widget.application.gpsCoordinates =
        "${latitudeController.text.trim()},${longitudeController.text.trim()}";

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TPMSAppBar(
        title: "GPS Location",
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
                currentStep: 4,
                totalSteps: 9,
                title: "GPS Location",
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        "Capture or Enter GPS Coordinates",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller:
                            latitudeController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(
                          labelText: "Latitude",
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextFormField(
                        controller:
                            longitudeController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration:
                            const InputDecoration(
                          labelText: "Longitude",
                          border:
                              OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child:
                            ElevatedButton.icon(
                          icon: const Icon(
                            Icons.my_location,
                          ),
                          label: Text(
                            widget.application
                                    .gpsCoordinates
                                    .isEmpty
                                ? "GET CURRENT GPS"
                                : "RE-CAPTURE GPS",
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(
                                    context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Automatic GPS capture will be enabled in the Android version.",
                                ),
                              ),
                            );
                          },
                        ),
                      ),
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
            ],
          ),
        ),
      ),
    );
  }
}