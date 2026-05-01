import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/location_service.dart';
import '../../../services/settings_controller.dart';
import '../../../utils/app_localizations.dart';

/// Yuqoridagi qidiruv satri + GPS «pill» — bitta suzuvchi klaster.
class MapStitchTopCluster extends StatelessWidget {
  final SettingsController settings;
  final int stationsCount;
  final VoidCallback onSearchPressed;
  final VoidCallback onStylePressed;
  final Widget? leading;
  final String? titleOverride;
  final String? secondaryLineOverride;

  const MapStitchTopCluster({
    super.key,
    required this.settings,
    required this.stationsCount,
    required this.onSearchPressed,
    required this.onStylePressed,
    this.leading,
    this.titleOverride,
    this.secondaryLineOverride,
  });

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 8;
    final hint = context.loc('map_search_locations_hint');
    final workshop = titleOverride != null || leading != null;
    if (workshop) {
      return _WorkshopTop(
        top: top,
        settings: settings,
        stationsCount: stationsCount,
        onStylePressed: onStylePressed,
        onSearchPressed: onSearchPressed,
        leading: leading,
        titleOverride: titleOverride,
        secondaryLineOverride: secondaryLineOverride,
      );
    }

    return Positioned(
      left: 10,
      right: 10,
      top: top,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.search_rounded, color: Color(0xFF37474F)),
                      onPressed: onSearchPressed,
                      tooltip: hint,
                    ),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: onSearchPressed,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                            child: Text(
                              hint,
                              style: TextStyle(
                                color: Colors.blueGrey.shade600,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.layers_outlined, color: Color(0xFF1976D2)),
                      onPressed: onStylePressed,
                      tooltip: context.loc('map_style'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const _StitchGpsPill(),
        ],
      ),
    );
  }
}

class _WorkshopTop extends StatelessWidget {
  final double top;
  final SettingsController settings;
  final int stationsCount;
  final VoidCallback onSearchPressed;
  final VoidCallback onStylePressed;
  final Widget? leading;
  final String? titleOverride;
  final String? secondaryLineOverride;

  const _WorkshopTop({
    required this.top,
    required this.settings,
    required this.stationsCount,
    required this.onSearchPressed,
    required this.onStylePressed,
    this.leading,
    this.titleOverride,
    this.secondaryLineOverride,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 10,
      right: 10,
      top: top,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
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
                ),
                IconButton(
                  icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                  onPressed: onSearchPressed,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StitchGpsPill extends StatelessWidget {
  const _StitchGpsPill();

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocationService>();
    final loc = locService.currentPosition;
    final status = locService.status;

    Color statusColor;
    String statusText;
    switch (status) {
      case GpsStatus.good:
        statusColor = Colors.green;
        statusText = 'GPS: ${loc?.accuracy.toStringAsFixed(1)} m';
        break;
      case GpsStatus.medium:
        statusColor = Colors.orange;
        statusText = 'GPS: ${loc?.accuracy.toStringAsFixed(1)} m';
        break;
      case GpsStatus.poor:
        statusColor = Colors.red;
        statusText = 'GPS: ${context.loc('gps_status_poor_short')}';
        break;
      case GpsStatus.searching:
        statusColor = Colors.orangeAccent;
        statusText = 'GPS…';
        break;
      default:
        statusColor = Colors.red;
        statusText = 'GPS Off';
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 220),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.66),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withValues(alpha: 0.85), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.satellite_alt, color: statusColor, size: 16),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  statusText,
                  style: const TextStyle(
                    color: Color(0xFF263238),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
