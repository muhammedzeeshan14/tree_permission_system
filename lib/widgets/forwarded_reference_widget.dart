import 'package:flutter/material.dart';
import '../utils/date_picker_util.dart';

class ForwardReference {

  int? sourceId;

  String sourceKind;

  String sourceName;

  String referenceNumber;

  String referenceDate;

  ForwardReference({

    this.sourceId,

    this.sourceKind = "SOURCE",

    this.sourceName = "",

    this.referenceNumber = "",

    this.referenceDate = "",

  });

  String get key =>
      "${sourceKind}_${sourceId ?? ""}";

}

class ForwardedReferenceWidget extends StatelessWidget {

  final String applicationSource;

  final String forwardedDate;

  final List<ForwardReference> references;

  final List<Map<String, dynamic>> sourceList;

  final ValueChanged<String> onSourceChanged;

  final ValueChanged<String> onForwardedDateChanged;

  final VoidCallback onAddReference;

  final void Function(int index) onRemoveReference;

  final void Function(
    int index,
    int? sourceId,
    String sourceName,
    String sourceKind,
  ) onSourceSelected;

  final void Function(
    int index,
    String value,
  ) onReferenceNumberChanged;

  final void Function(
    int index,
    String value,
  ) onReferenceDateChanged;

  const ForwardedReferenceWidget({

    super.key,

    required this.applicationSource,

    required this.forwardedDate,

    required this.references,

    required this.sourceList,

    required this.onSourceChanged,

    required this.onForwardedDateChanged,

    required this.onAddReference,

    required this.onRemoveReference,

    required this.onSourceSelected,

    required this.onReferenceNumberChanged,

    required this.onReferenceDateChanged,

  });

  @override
  Widget build(BuildContext context) {

    return Column(

      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        DropdownButtonFormField<String>(

          value: applicationSource,

          decoration: const InputDecoration(

            labelText: "Application Source",

            border: OutlineInputBorder(),

          ),

          items: const [

            DropdownMenuItem(

              value: "DIRECT",

              child: Text("Received Directly"),

            ),

            DropdownMenuItem(

              value: "FORWARDED",

              child: Text(
                "Received Through Forwarding",
              ),

            ),

          ],

          onChanged: (v) {

            if (v != null) {

              onSourceChanged(v);

            }

          },

        ),

        if (applicationSource == "FORWARDED") ...[


          const SizedBox(height: 20),

          Row(

            children: [

              const Expanded(

                child: Text(

                  "Reference Applications",

                  style: TextStyle(

                    fontWeight: FontWeight.bold,

                    fontSize: 16,

                  ),

                ),

              ),

              ElevatedButton.icon(

                onPressed: onAddReference,

                icon: const Icon(Icons.add),

                label: const Text("ADD REFERENCE"),

              ),

            ],

          ),

          const SizedBox(height: 10),

          ...List.generate(

            references.length,

            (index) {

              final ref = references[index];

              return Padding(

                padding:
                    const EdgeInsets.only(bottom: 10),

                child: Row(

                  children: [

                    Expanded(

                      flex: 3,

                      child:
                          DropdownButtonFormField<String>(

                        value: ref.sourceId == null
                            ? null
                            : ref.key,

                        decoration:
                            const InputDecoration(

                          labelText: "Forwarded By",

                          border:
                              OutlineInputBorder(),

                        ),

                        items: sourceList.map((e) {

                          final key =
                              "${e["sourceKind"] ?? "SOURCE"}_${e["id"]}";

                          return DropdownMenuItem<String>(

                            value: key,

                            child: Text(

                              e["sourceName"],

                            ),

                          );

                        }).toList(),

                        onChanged: (key) {

                          if (key == null) return;

                          final selected =
                              sourceList.firstWhere(

                            (e) =>
                                "${e["sourceKind"] ?? "SOURCE"}_${e["id"]}" ==
                                key,

                          );

                          onSourceSelected(

                            index,

                            selected["id"] as int?,

                            selected["sourceName"]
                                    ?.toString() ??
                                "",

                            (selected["sourceKind"]
                                    ?.toString() ??
                                "SOURCE"),

                          );

                        },

                      ),

                    ),

                    const SizedBox(width: 10),

                    Expanded(

                      flex: 3,

                      child: TextFormField(

                        initialValue:
                            ref.referenceNumber,

                        decoration:
                            const InputDecoration(

                          labelText: "Reference No",

                          border:
                              OutlineInputBorder(),

                        ),

                        onChanged: (v) {

                          onReferenceNumberChanged(

                            index,

                            v,

                          );

                        },

                      ),

                    ),

                    const SizedBox(width: 10),

                    Expanded(

  flex: 2,

  child: Builder(

    builder: (context) {

      final controller = TextEditingController(
        text: ref.referenceDate,
      );

      return TextFormField(

        controller: controller,

        readOnly: true,

        decoration: const InputDecoration(

          labelText: "Date",

          border: OutlineInputBorder(),

          suffixIcon: Icon(Icons.calendar_month),

        ),

        onTap: () async {

          await DatePickerUtil.pickDate(

            context,

            controller,

          );

          onReferenceDateChanged(

            index,

            controller.text,

          );

        },

      );

    },

  ),

),

                    IconButton(

                      onPressed: () {

                        onRemoveReference(index);

                      },

                      icon: const Icon(

                        Icons.delete,

                        color: Colors.red,

                      ),

                    ),

                  ],

                ),

              );

            },

          ),

        ],

      ],

    );

  }

}