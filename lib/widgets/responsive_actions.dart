import 'package:flutter/material.dart';

/// Item 7: side-by-side buttons on desktop, stacked on mobile.
///
/// On wide screens (>= 600dp) children sit in a Row with equal width.
/// On narrow screens they stack vertically, full width, so labels never
/// wrap/clip into each other.
class ResponsiveActions extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double breakpoint;

  const ResponsiveActions({
    super.key,
    required this.children,
    this.spacing = 12,
    this.breakpoint = 600,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final wide =
        MediaQuery.sizeOf(context).width >= breakpoint;
    if (wide) {
      return Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(width: spacing),
            Expanded(child: children[i]),
          ],
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          children[i],
        ],
      ],
    );
  }
}
