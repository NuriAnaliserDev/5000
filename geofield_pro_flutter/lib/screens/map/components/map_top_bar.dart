import 'package:flutter/material.dart';
import '../../../utils/app_card.dart';
import '../../../services/settings_controller.dart';
import '../../../utils/app_localizations.dart';

class MapTopBar extends StatelessWidget {
  final int stationsCount;
  final SettingsController settings;
  final VoidCallback onStylePressed;
  final VoidCallback onSearchPressed;
  /// Masalan: Pro maydon (field workshop) ekranida sarlavha va orqaga chiqish.
  final Widget? leading;
  final String? titleOverride;
  final String? secondaryLineOverride;

  const MapTopBar({
    super.key,
    required this.stationsCount,
    required this.settings,
    required this.onStylePressed,
    required this.onSearchPressed,
    this.leading,
    this.titleOverride,
    this.secondaryLineOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      left: 10,
      right: 10,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 4)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titleOverride ?? settings.currentProject,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    secondaryLineOverride ?? '$stationsCount ${context.loc('stations')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.layers_outlined, color: Theme.of(context).colorScheme.primary),
              onPressed: onStylePressed,
              tooltip: context.loc('map_style'),
            ),
            IconButton(
              icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
              onPressed: onSearchPressed,
            ),
          ],
        ),
      ),
    );
  }
}
