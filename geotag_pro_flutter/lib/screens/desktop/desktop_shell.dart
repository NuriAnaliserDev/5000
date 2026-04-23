import 'package:flutter/material.dart';

import '../dashboard_screen.dart';
import 'desktop_sidebar.dart';

/// Windows/macOS/Linux ilovaning asosiy shelli (skeleton).
///
/// Hozirgi versiyada chap sidebar + markazda mobil Dashboard ekranining
/// maxsus (kengaytirilgan) ko‘rinishi. Map canvas editor, data console va
/// admin paneli alohida bosqichlarda to‘ldiriladi (roadmap 7.2-7.4, 7.9).
class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key});

  @override
  State<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends State<DesktopShell> {
  DesktopSection _section = DesktopSection.dashboard;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            DesktopSidebar(
              current: _section,
              onSelect: (s) => setState(() => _section = s),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_section) {
      case DesktopSection.dashboard:
        return const DashboardScreen();
      case DesktopSection.map:
        return const _PlaceholderPanel(
          icon: Icons.map_outlined,
          title: 'Xarita tahrirchisi',
          description:
              'Vektor tahrirchi (snap, undo/redo, topology) roadmap 7.3\'da to‘ldiriladi.',
        );
      case DesktopSection.console:
        return const _PlaceholderPanel(
          icon: Icons.storage_outlined,
          title: 'Ma\'lumotlar konsoli',
          description:
              'Advanced filter, bulk edit va import preview roadmap 7.4\'da to‘ldiriladi.',
        );
      case DesktopSection.admin:
        return const _PlaceholderPanel(
          icon: Icons.shield_outlined,
          title: 'Admin paneli',
          description:
              'User va project boshqaruvi roadmap 7.9\'da to‘ldiriladi.',
        );
    }
  }
}

class _PlaceholderPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _PlaceholderPanel({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 96, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              description,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
