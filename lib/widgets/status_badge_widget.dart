import 'package:flutter/material.dart';

/// Semantic status badge — colored Container with BorderRadius.
/// Never plain text for status values.
class StatusBadgeWidget extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const StatusBadgeWidget({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(46),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(102), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
