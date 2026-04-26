import 'package:flutter/material.dart';

enum DesktopSection { dashboard, map, console, admin }

extension DesktopSectionX on DesktopSection {
  String get label {
    switch (this) {
      case DesktopSection.dashboard:
        return 'Dashboard';
      case DesktopSection.map:
        return 'Xarita';
      case DesktopSection.console:
        return 'Konsol';
      case DesktopSection.admin:
        return 'Admin';
    }
  }

  IconData get icon {
    switch (this) {
      case DesktopSection.dashboard:
        return Icons.dashboard_outlined;
      case DesktopSection.map:
        return Icons.map_outlined;
      case DesktopSection.console:
        return Icons.storage_outlined;
      case DesktopSection.admin:
        return Icons.shield_outlined;
    }
  }
}

class DesktopSidebar extends StatelessWidget {
  final DesktopSection current;
  final ValueChanged<DesktopSection> onSelect;

  const DesktopSidebar({
    super.key,
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Material(
        color: theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.explore, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text('GeoField Pro',
                      style: theme.textTheme.titleMedium),
                ],
              ),
            ),
            const SizedBox(height: 24),
            for (final s in DesktopSection.values)
              _NavItem(
                section: s,
                selected: s == current,
                onTap: () => onSelect(s),
              ),
            const Spacer(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Desktop v0.7 (skeleton)',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final DesktopSection section;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.section,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = selected ? theme.colorScheme.primary.withValues(alpha: .12) : null;
    final fg = selected ? theme.colorScheme.primary : theme.colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: bg,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(section.icon, color: fg, size: 20),
            const SizedBox(width: 12),
            Text(section.label, style: TextStyle(color: fg)),
          ],
        ),
      ),
    );
  }
}
