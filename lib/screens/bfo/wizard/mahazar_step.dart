import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/application_model.dart';
import '../../../widgets/responsive_actions.dart';
import '../../../models/mahazar_model.dart';
import '../../../repositories/mahazar_repository.dart';
import '../../../repositories/master_repository.dart';

class MahazarStep extends StatefulWidget {
  final ApplicationModel application;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const MahazarStep({
    super.key,
    required this.application,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<MahazarStep> createState() =>
      _MahazarStepState();
}

class _MahazarStepState extends State<MahazarStep> {
  final _formKey = GlobalKey<FormState>();

  final repo = MahazarRepository();
  final masterRepository = MasterRepository();

  final startHourController =
    TextEditingController();

final startMinuteController =
    TextEditingController();

final endHourController =
    TextEditingController();

final endMinuteController =
    TextEditingController();

  final northController =
      TextEditingController();

  final eastController =
      TextEditingController();

  final southController =
      TextEditingController();

  final westController =
      TextEditingController();

  DateTime? mahazarDate;

  String startPeriod = "AM";
  String endPeriod = "PM";

  int? northLocationId;
  int? eastLocationId;
  int? southLocationId;
  int? westLocationId;

  List<Map<String, dynamic>> locationList = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final data = await repo.getByApplication(
      widget.application.id!,
    );

    if (data != null) {
      if (data.mahazarDate.isNotEmpty) {
        mahazarDate =
            DateTime.tryParse(data.mahazarDate);
      }

      northLocationId =
          data.northLocationId;

      eastLocationId =
          data.eastLocationId;

      southLocationId =
          data.southLocationId;

      westLocationId =
          data.westLocationId;

      northController.text =
          data.northBoundary;

      eastController.text =
          data.eastBoundary;

      southController.text =
          data.southBoundary;

      westController.text =
          data.westBoundary;

      final storedStart =
          data.startTimeManual.trim().isNotEmpty
              ? data.startTimeManual
              : data.startTime;

      final storedEnd =
          data.endTimeManual.trim().isNotEmpty
              ? data.endTimeManual
              : data.endTime;

      final parsedStart =
          _parseStoredTime(storedStart);

      final parsedEnd =
          _parseStoredTime(storedEnd);

      final startParts =
    (parsedStart["time"] ?? "").split(":");

if (startParts.length == 2) {
  startHourController.text =
      startParts[0];

  startMinuteController.text =
      startParts[1];
}

startPeriod =
    parsedStart["period"] ?? "AM";

final endParts =
    (parsedEnd["time"] ?? "").split(":");

if (endParts.length == 2) {
  endHourController.text =
      endParts[0];

  endMinuteController.text =
      endParts[1];
}

endPeriod =
    parsedEnd["period"] ?? "PM";
    }

    final allLocations =
        await masterRepository.getMasters(
      "Mahazar Location",
    );

    locationList = allLocations.where((item) {
      return item["isActive"] == 1 ||
          item["id"] == northLocationId ||
          item["id"] == eastLocationId ||
          item["id"] == southLocationId ||
          item["id"] == westLocationId;
    }).toList();

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  Map<String, String> _parseStoredTime(
    String stored,
  ) {
    final value =
        stored.trim().toUpperCase();

    if (value.isEmpty) {
      return {
        "time": "",
        "period": "AM",
      };
    }

    final twelveHourMatch = RegExp(
      r'^(0?[1-9]|1[0-2]):([0-5][0-9])\s*(AM|PM)$',
    ).firstMatch(value);

    if (twelveHourMatch != null) {
      final hour = twelveHourMatch
          .group(1)!
          .padLeft(2, "0");

      final minute =
          twelveHourMatch.group(2)!;

      return {
        "time": "$hour:$minute",
        "period":
            twelveHourMatch.group(3)!,
      };
    }

    final parts = value.split(":");

    if (parts.length == 2) {
      final hour =
          int.tryParse(parts[0].trim());

      final minuteText =
          parts[1]
              .replaceAll(
                RegExp(r'[^0-9]'),
                '',
              )
              .padLeft(2, "0");

      final minute =
          int.tryParse(minuteText);

      if (hour != null &&
          hour >= 0 &&
          hour <= 23 &&
          minute != null &&
          minute >= 0 &&
          minute <= 59) {
        final period =
            hour >= 12 ? "PM" : "AM";

        var twelveHour = hour % 12;

        if (twelveHour == 0) {
          twelveHour = 12;
        }

        return {
          "time":
              "${twelveHour.toString().padLeft(2, "0")}:${minute.toString().padLeft(2, "0")}",
          "period": period,
        };
      }
    }

    return {
      "time": "",
      "period": "AM",
    };
  }

  Future<void> pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate:
          mahazarDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        mahazarDate = selected;
      });
    }
  }

  String? _validateHour(String? value) {
  final hour =
      int.tryParse(value?.trim() ?? "");

  if (hour == null) {
    return "Required";
  }

  if (hour < 1 || hour > 12) {
    return "1–12";
  }

  return null;
}

String? _validateMinute(String? value) {
  final minute =
      int.tryParse(value?.trim() ?? "");

  if (minute == null) {
    return "Required";
  }

  if (minute < 0 || minute > 59) {
    return "0–59";
  }

  return null;
}

  String _normalisedTime(
  String hourValue,
  String minuteValue,
  String period,
) {
  final hour =
      int.parse(hourValue.trim());

  final minute =
      int.parse(minuteValue.trim());

  return "${hour.toString().padLeft(2, "0")}:"
      "${minute.toString().padLeft(2, "0")} "
      "$period";
}

   String _displayMaster(
    Map<String, dynamic> item,
  ) {
    return item["value"]?.toString().trim() ?? "";
  }

  Widget _timeEntry({
  required String title,
  required TextEditingController hourController,
  required TextEditingController minuteController,
  required String period,
  required ValueChanged<String?> onPeriodChanged,
}) {
  return Row(
    crossAxisAlignment:
        CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 150,
        child: Padding(
          padding:
              const EdgeInsets.only(top: 18),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),

      SizedBox(
        width: 100,
        child: TextFormField(
          controller: hourController,
          keyboardType:
              TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter
                .digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          validator: _validateHour,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            labelText: "HH",
            hintText: "09",
            counterText: "",
            border: OutlineInputBorder(),
          ),
        ),
      ),

      const Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        child: Text(
          ":",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      SizedBox(
        width: 100,
        child: TextFormField(
          controller: minuteController,
          keyboardType:
              TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter
                .digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          validator: _validateMinute,
          textAlign: TextAlign.center,
          decoration: const InputDecoration(
            labelText: "MM",
            hintText: "30",
            counterText: "",
            border: OutlineInputBorder(),
          ),
        ),
      ),

      const SizedBox(width: 12),

      SizedBox(
        width: 110,
        child: DropdownButtonFormField<String>(
          value: period,
          decoration: const InputDecoration(
            labelText: "AM/PM",
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
              value: "AM",
              child: Text("AM"),
            ),
            DropdownMenuItem(
              value: "PM",
              child: Text("PM"),
            ),
          ],
          onChanged: onPeriodChanged,
        ),
      ),
    ],
  );
}

  Widget _boundaryEntry({
    required String direction,
    required int? selectedLocationId,
    required ValueChanged<int?> onLocationChanged,
    required TextEditingController controller,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 75,
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 18),
              child: Text(
                direction,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          Expanded(
            flex: 2,
            child:
                DropdownButtonFormField<int>(
              value: locationList.any(
                (item) =>
                    item["id"] ==
                    selectedLocationId,
              )
                  ? selectedLocationId
                  : null,
              validator: (value) {
                if (value == null) {
                  return "Select location";
                }

                return null;
              },
              decoration:
                  const InputDecoration(
                labelText:
                    "Mahazar Location",
                border:
                    OutlineInputBorder(),
              ),
              items: locationList.map((item) {
                return DropdownMenuItem<int>(
                  value: item["id"] as int,
                  child: Text(
                    _displayMaster(item),
                  ),
                );
              }).toList(),
              onChanged: onLocationChanged,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            flex: 2,
            child: TextFormField(
              controller: controller,
              decoration:
                  const InputDecoration(
                labelText:
                    "Additional details (optional)",
                border:
                    OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> save() async {
    if (mahazarDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            "Please select Mahazar Date.",
          ),
        ),
      );

      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    await repo.save(
      MahazarModel(
        applicationId:
            widget.application.id!,
        mahazarDate:
            mahazarDate!.toIso8601String(),
        startTime: _normalisedTime(
  startHourController.text,
  startMinuteController.text,
  startPeriod,
),
        endTime: _normalisedTime(
  endHourController.text,
  endMinuteController.text,
  endPeriod,
),
        endTimeManual: "",
        northLocationId:
            northLocationId,
        eastLocationId:
            eastLocationId,
        southLocationId:
            southLocationId,
        westLocationId:
            westLocationId,
        northBoundary:
            northController.text.trim(),
        eastBoundary:
            eastController.text.trim(),
        southBoundary:
            southController.text.trim(),
        westBoundary:
            westController.text.trim(),
      ),
    );

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Mahazar Details"),
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Form(
              key: _formKey,
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      child: ListTile(
                        title: const Text(
                          "Mahazar Date",
                        ),
                        subtitle: Text(
                          mahazarDate == null
                              ? "Select Date"
                              : "${mahazarDate!.day.toString().padLeft(2, "0")}-${mahazarDate!.month.toString().padLeft(2, "0")}-${mahazarDate!.year}",
                        ),
                        trailing: const Icon(
                          Icons.calendar_month,
                        ),
                        onTap: pickDate,
                      ),
                    ),

                    const SizedBox(height: 16),

                    _timeEntry(
  title: "Starting Time",
  hourController:
      startHourController,
  minuteController:
      startMinuteController,
  period: startPeriod,
                      onPeriodChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          startPeriod = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    _timeEntry(
  title: "Ending Time",
  hourController:
      endHourController,
  minuteController:
      endMinuteController,
  period: endPeriod,
                      onPeriodChanged: (value) {
                        if (value == null) return;

                        setState(() {
                          endPeriod = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child:
                          SingleChildScrollView(
                        child: Column(
                          children: [
                            _boundaryEntry(
                              direction: "North",
                              selectedLocationId:
                                  northLocationId,
                              onLocationChanged:
                                  (value) {
                                setState(() {
                                  northLocationId =
                                      value;
                                });
                              },
                              controller:
                                  northController,
                            ),
                            _boundaryEntry(
                              direction: "East",
                              selectedLocationId:
                                  eastLocationId,
                              onLocationChanged:
                                  (value) {
                                setState(() {
                                  eastLocationId =
                                      value;
                                });
                              },
                              controller:
                                  eastController,
                            ),
                            _boundaryEntry(
                              direction: "South",
                              selectedLocationId:
                                  southLocationId,
                              onLocationChanged:
                                  (value) {
                                setState(() {
                                  southLocationId =
                                      value;
                                });
                              },
                              controller:
                                  southController,
                            ),
                            _boundaryEntry(
                              direction: "West",
                              selectedLocationId:
                                  westLocationId,
                              onLocationChanged:
                                  (value) {
                                setState(() {
                                  westLocationId =
                                      value;
                                });
                              },
                              controller:
                                  westController,
                            ),
                          ],
                        ),
                      ),
                    ),

                    ResponsiveActions(
                      children: [
                        ElevatedButton(
                            onPressed:
                                widget.onBack,
                            child:
                                const Text("BACK"),
                          ),


                        ElevatedButton(
                            onPressed: save,
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

  @override
  void dispose() {
    startHourController.dispose();
startMinuteController.dispose();
endHourController.dispose();
endMinuteController.dispose();
    northController.dispose();
    eastController.dispose();
    southController.dispose();
    westController.dispose();
    super.dispose();
  }
}