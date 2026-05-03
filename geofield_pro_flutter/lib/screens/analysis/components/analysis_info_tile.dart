import 'package:flutter/material.dart';

class AnalysisInfoTile extends StatelessWidget {
  const AnalysisInfoTile(
      {super.key,
      required this.icon,
      required this.label,
      required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onSurf = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1976D2)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: onSurf.withValues(alpha: 0.7), fontSize: 13))),
          Text(value,
              style: const TextStyle(
                  color: Color(0xFF1976D2),
                  fontSize: 14,
                  fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}
