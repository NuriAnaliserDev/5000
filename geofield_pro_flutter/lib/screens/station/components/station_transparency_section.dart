import 'package:flutter/material.dart';
import '../../../models/station.dart';

class StationTransparencySection extends StatelessWidget {
  final Station station;
  final VoidCallback onShowAudit;
  final VoidCallback onExportPdf;

  const StationTransparencySection({
    super.key,
    required this.station,
    required this.onShowAudit,
    required this.onExportPdf,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formFill = isDark ? const Color(0xFF181818) : Colors.grey.shade200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "SHAFFOFLIK VA HISOBOT (JORC)",
          style: TextStyle(fontSize: 11, letterSpacing: 2, color: Colors.grey, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: formFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildItem(
                context,
                icon: Icons.history,
                title: 'O\'zgarishlar Tarixi',
                subtitle: '${station.history?.length ?? 0} ta o\'zgarish qayd etilgan',
                onTap: onShowAudit,
                color: Colors.orange,
              ),
              const Divider(height: 24),
              _buildItem(
                context,
                icon: Icons.verified_user,
                title: 'Professional JORC Hisobot',
                subtitle: 'Sifat nazorati va auditga tayyor',
                onTap: onExportPdf,
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        ],
      ),
    );
  }
}
