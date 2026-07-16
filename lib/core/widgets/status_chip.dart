import 'package:flutter/material.dart';

/// A small status pill that communicates state via both color and text,
/// so information is never conveyed by color alone.
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color backgroundColor;

  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
