import 'package:flutter/material.dart';

import '../../utils/status_semantics.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.level,
    this.icon,
    this.fontSize = 10,
    this.horizontal = 8,
    this.vertical = 4,
  });

  final String label;
  final StatusLevel level;
  final IconData? icon;
  final double fontSize;
  final double horizontal;
  final double vertical;

  @override
  Widget build(BuildContext context) {
    final color = StatusSemantics.colorFor(level);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
