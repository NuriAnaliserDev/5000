import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/settings_controller.dart';
import '../../../utils/app_localizations.dart';

class DashboardDesktopProjectSection extends StatelessWidget {
  const DashboardDesktopProjectSection({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final settings = context.watch<SettingsController>();
    final currentProj = settings.currentProject;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_open, color: Colors.indigo, size: 22),
              const SizedBox(width: 12),
              const Text('Active Project', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              _ProjectPicker(
                projects: settings.projects,
                current: currentProj,
                onSelect: (p) => settings.currentProject = p,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _infoCard('Project ID', currentProj, Colors.blue),
              const SizedBox(width: 12),
              _infoCard('Type', 'Geological Survey', Colors.purple),
              const SizedBox(width: 12),
              _infoCard('Status', 'Active', Colors.teal),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _ProjectPicker extends StatelessWidget {
  final List<String> projects;
  final String current;
  final Function(String) onSelect;

  const _ProjectPicker({required this.projects, required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelect,
      itemBuilder: (ctx) => projects.map((p) => PopupMenuItem(value: p, child: Text(p))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.indigo.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(current, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
            const Icon(Icons.arrow_drop_down, color: Colors.indigo),
          ],
        ),
      ),
    );
  }
}
