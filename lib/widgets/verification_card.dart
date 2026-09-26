import 'package:flutter/material.dart';

class VerificationCard extends StatelessWidget {
  final String title;
  final String value;

  // Used by existing two-option verification screens.
  // null = Not verified
  // true = Correct
  // false = Re-inspect
  final bool? verification;
  final ValueChanged<bool?>? onChanged;

  // Used by DRFO three-option verification.
  // Values: Correct, Modify, Re-inspect
 final bool threeOptions;
final bool approvalOptions;
final bool approvalOptionsVertical;
final String? verificationStatus;
  final ValueChanged<String?>? onStatusChanged;

  // Field shown only when Modify is selected.
  final Widget? modifyField;

  final String? selectedReason;
  final List<String> reasons;
  final ValueChanged<String?>? onReasonChanged;

  final VoidCallback? onView;
  final bool horizontalOptions;

  const VerificationCard({
    super.key,
    required this.title,
    required this.value,
    this.verification,
    this.onChanged,
    this.threeOptions = false,
this.approvalOptions = false,
this.approvalOptionsVertical = false,
this.verificationStatus,
    this.onStatusChanged,
    this.modifyField,
    this.selectedReason,
    this.reasons = const [],
    this.onReasonChanged,
    this.onView,
    this.horizontalOptions = false,
  });

 @override
Widget build(BuildContext context) {
  Widget approvalRadio(
    String value,
    String label,
  ) {
    return RadioListTile<String>(
      dense: true,
      visualDensity:
          VisualDensity.compact,
      contentPadding:
          EdgeInsets.zero,
      value: value,
      groupValue:
          verificationStatus,
      title: Text(label),
      onChanged:
          onStatusChanged,
    );
  }

  return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 8),

              Text(value),

              if (onView != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.visibility),
                    label: const Text("View"),
                    onPressed: onView,
                  ),
                ),
              ],

if (approvalOptions)
  approvalOptionsVertical
      ? Column(
          children: [
            approvalRadio(
              "Approve",
              "Approve",
            ),
            approvalRadio(
              "Modify",
              "Modify",
            ),
            approvalRadio(
              "Re-inspect",
              "Re-inspect",
            ),
          ],
        )
      : Row(
          children: [
            Expanded(
              child: approvalRadio(
                "Approve",
                "Approve",
              ),
            ),
            Expanded(
              child: approvalRadio(
                "Modify",
                "Modify",
              ),
            ),
            Expanded(
              child: approvalRadio(
                "Re-inspect",
                "Re-inspect",
              ),
            ),
          ],
        )

else if (threeOptions)
  Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        value: "Correct",
                        groupValue: verificationStatus,
                        title: const Text("Correct"),
                        onChanged: onStatusChanged,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        value: "Modify",
                        groupValue: verificationStatus,
                        title: const Text("Modify"),
                        onChanged: onStatusChanged,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        value: "Re-inspect",
                        groupValue: verificationStatus,
                        title: const Text("Re-inspect"),
                        onChanged: onStatusChanged,
                      ),
                    ),
                  ],
                )
              else if (horizontalOptions)
                Wrap(
                  spacing: 20,
                  runSpacing: 0,
                  children: [
                    SizedBox(
                      width: 150,
                      child: RadioListTile<bool>(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        value: true,
                        groupValue: verification,
                        title: const Text("Correct"),
                        onChanged: onChanged,
                      ),
                    ),
                    SizedBox(
                      width: 170,
                      child: RadioListTile<bool>(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        contentPadding: EdgeInsets.zero,
                        value: false,
                        groupValue: verification,
                        title: const Text("Re-inspect"),
                        onChanged: onChanged,
                      ),
                    ),
                  ],
                )
              else ...[
                RadioListTile<bool>(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  value: true,
                  groupValue: verification,
                  title: const Text("Correct"),
                  onChanged: onChanged,
                ),
                RadioListTile<bool>(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  contentPadding: EdgeInsets.zero,
                  value: false,
                  groupValue: verification,
                  title: const Text("Re-inspect"),
                  onChanged: onChanged,
                ),
              ],

if ((threeOptions || approvalOptions) &&
    verificationStatus == "Modify" &&
    modifyField != null) ...[
                const SizedBox(height: 8),
                modifyField!,
              ],

              if (((threeOptions || approvalOptions) &&
        verificationStatus == "Re-inspect") ||
    (!threeOptions &&
        !approvalOptions &&
        verification == false)) ...[
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: selectedReason,
                  decoration: const InputDecoration(
                    labelText: "Verification Reason",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: reasons
                      .map(
                        (reason) => DropdownMenuItem<String>(
                          value: reason,
                          child: Text(reason),
                        ),
                      )
                      .toList(),
                  onChanged: onReasonChanged,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}