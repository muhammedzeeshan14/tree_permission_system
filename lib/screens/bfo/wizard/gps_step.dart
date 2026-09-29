import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../../../widgets/workflow_action.dart';
import 'package:flutter/material.dart';

import '../../../widgets/responsive_actions.dart';
import '../../../models/application_model.dart';

import '../../../widgets/application_header_card.dart';
import '../../../widgets/tpms_app_bar.dart';
import '../../../widgets/wizard_progress_card.dart';

class GPSStep extends StatefulWidget {
  final ApplicationModel application;

  final FutureOr<void> Function() onNext;

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

  Future<void> _saveAndContinue() async {
    if (!_validCoordinate(latitudeController.text, 90) ||
        !_validCoordinate(longitudeController.text, 180)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Enter valid latitude (-90 to 90) and longitude (-180 to 180).",
          ),
        ),
      );
      return;
    }

    widget.application.gpsCoordinates =
        "${latitudeController.text.trim()},${longitudeController.text.trim()}";

    await widget.onNext();
  }

  bool _validCoordinate(String text, double limit) {
    final value = double.tryParse(text.trim());
    return value != null && value.isFinite && value.abs() <= limit;
  }

  Future<void> _captureGps() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      if (!mounted) return;
      _locationMessage('Turn on Location Services, then capture GPS again.', Geolocator.openLocationSettings);
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    if (permission == LocationPermission.deniedForever) {
      _locationMessage('Allow location access in app settings, then capture GPS again.', Geolocator.openAppSettings);
      return;
    }
    if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
      _locationMessage('Location permission is needed to capture GPS. You can also enter coordinates manually.');
      return;
    }
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 30)),
      );
      if (!mounted) return;
      setState(() {
        latitudeController.text = position.latitude.toStringAsFixed(7);
        longitudeController.text = position.longitude.toStringAsFixed(7);
      });
      _locationMessage('Location captured. Press Save & Continue to save it.');
    } on TimeoutException {
      if (mounted) _locationMessage('GPS could not get a fix. Move to an open area and try again.');
    }
  }

  void _locationMessage(String message, [Future<bool> Function()? settings]) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      action: settings == null ? null : SnackBarAction(label: 'Settings', onPressed: () async { await settings(); }),
    ));
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
                          decimal: true, signed: true,
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
                          decimal: true, signed: true,
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
                          onPressed: workflowAction(context, _captureGps),
                        ),
                      ),
                                            const SizedBox(height: 30),

                      ResponsiveActions(
                        children: [
                          ElevatedButton(
                            onPressed: workflowAction(context, widget.onBack),
                            child: const Text(
                              "BACK",
                            ),
                          ),
                          ElevatedButton(
                            onPressed:
                                workflowAction(context, _saveAndContinue),
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