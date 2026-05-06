import 'package:flutter/material.dart';

import '../../services/settings_controller.dart';
import '../../utils/app_card.dart';
import '../../utils/app_localizations.dart';

class AdminProfileCard extends StatelessWidget {
  const AdminProfileCard({
    super.key,
    required this.settings,
    required this.onSurfaceColor,
  });

  final SettingsController settings;
  final Color onSurfaceColor;

  @override
  Widget build(BuildContext context) {
    final name = settings.currentUserName ?? context.loc('dashboard');
    final initial =
        name.isNotEmpty ? name.trim().substring(0, 1).toUpperCase() : 'G';
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        opacity: isDark ? 0.14 : 0.45,
        blur: 18,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.loc('profile_section_label'),
              style: TextStyle(
                color: onSurfaceColor.withValues(alpha: 0.7),
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      const Color(0xFF1976D2).withValues(alpha: 0.2),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1976D2),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        settings.expertMode
                            ? context.loc('role_geologist_admin')
                            : 'Geolog',
                        style: TextStyle(
                            fontSize: 12,
                            color: onSurfaceColor.withValues(alpha: 0.55)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AdminGradientPillButton extends StatelessWidget {
  const AdminGradientPillButton({
    super.key,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.colors,
  });

  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: colors),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
