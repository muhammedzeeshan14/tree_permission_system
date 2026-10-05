import 'package:flutter/material.dart';

/// Keeps the label readable on narrow screens and colours only the count.
class DashboardCountLabel extends StatelessWidget {
  final String label;
  final int? count;
  final bool positiveIsGreen;

  const DashboardCountLabel({
    super.key,
    required this.label,
    required this.count,
    this.positiveIsGreen = false,
  });

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(text: label),
        if (count != null)
          TextSpan(
            text: ' ($count)',
            style: TextStyle(
              color: count == 0 || positiveIsGreen ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
      ],
    ),
  );
}
