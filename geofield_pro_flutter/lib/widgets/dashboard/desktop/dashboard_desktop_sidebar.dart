import 'package:flutter/material.dart';

class DashboardDesktopSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelected;

  const DashboardDesktopSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: t.colorScheme.surface,
        border: Border(
            right: BorderSide(color: t.dividerColor.withValues(alpha: 0.5))),
      ),
      child: Column(
        children: [
          _buildBrand(t),
          const SizedBox(height: 32),
          _buildItem(context, 0, Icons.dashboard_outlined, Icons.dashboard,
              'Workbench'),
          _buildItem(context, 1, Icons.map_outlined, Icons.map, 'Field Map'),
          _buildItem(context, 2, Icons.analytics_outlined, Icons.analytics,
              'Analytics'),
          _buildItem(
              context, 3, Icons.cloud_outlined, Icons.cloud, 'Cloud Sync'),
          const Spacer(),
          _buildItem(
              context, 4, Icons.settings_outlined, Icons.settings, 'Settings'),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBrand(ThemeData t) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: t.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.terrain, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GeoField',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  color: t.colorScheme.onSurface,
                ),
              ),
              Text(
                'PRO WORKSTATION',
                style: TextStyle(
                  fontSize: 10,
                  color: t.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    int index,
    IconData icon,
    IconData activeIcon,
    String label,
  ) {
    final t = Theme.of(context);
    final c = t.colorScheme;
    final isSelected = selectedIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => onSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? c.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? c.primary : c.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? c.primary
                      : c.onSurface.withValues(alpha: 0.75),
                ),
              ),
              if (isSelected) ...[
                const Spacer(),
                Container(
                  width: 4,
                  height: 4,
                  decoration:
                      BoxDecoration(color: c.primary, shape: BoxShape.circle),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
