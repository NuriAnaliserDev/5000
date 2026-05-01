import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_strings.dart';
import '../../../services/track_service.dart';

/// O‘ng chetki dumaloq «shisha» tugmalar.
class MapStitchRightRail extends StatelessWidget {
  final VoidCallback onDraw;
  final VoidCallback onAddStation;
  final VoidCallback onFollowToggle;
  final bool followActive;
  final VoidCallback onMyLocation;

  const MapStitchRightRail({
    super.key,
    required this.onDraw,
    required this.onAddStation,
    required this.onFollowToggle,
    required this.followActive,
    required this.onMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.sizeOf(context).height;
    final top = h * 0.26;
    return Positioned(
      right: 8,
      top: top,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GlassCircle(icon: Icons.auto_fix_high_outlined, onTap: onDraw),
          const SizedBox(height: 10),
          _GlassCircle(icon: Icons.add_location_alt_outlined, onTap: onAddStation),
          const SizedBox(height: 10),
          _GlassCircle(
            icon: followActive ? Icons.navigation_rounded : Icons.wifi_tethering_rounded,
            onTap: onFollowToggle,
            filled: followActive,
          ),
          const SizedBox(height: 10),
          _GlassCircle(icon: Icons.gps_fixed_rounded, onTap: onMyLocation),
        ],
      ),
    );
  }
}

class _GlassCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _GlassCircle({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        customBorder: const CircleBorder(),
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled
                    ? const Color(0xFF1976D2).withValues(alpha: 0.9)
                    : Colors.white.withValues(alpha: 0.88),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: filled ? Colors.white : const Color(0xFF455A64),
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pastki-o‘ng «Ultra Pro» radial hub.
class MapStitchRadialDock extends StatelessWidget {
  final VoidCallback onProTools;
  final VoidCallback onStrikeDip;
  final VoidCallback onSampling;
  final VoidCallback onFieldNotes;
  final VoidCallback onProjectLayers;

  const MapStitchRadialDock({
    super.key,
    required this.onProTools,
    required this.onStrikeDip,
    required this.onSampling,
    required this.onFieldNotes,
    required this.onProjectLayers,
  });

  @override
  Widget build(BuildContext context) {
    final s = GeoFieldStrings.of(context);
    if (s == null) return const SizedBox.shrink();

    return Consumer<TrackService>(
      builder: (context, trackSvc, _) {
        final trackOn = trackSvc.isTracking;
        return SizedBox(
          width: 260,
          height: 220,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomRight,
            children: [
              _RadialSatellite(
                label: s.map_radial_strike_dip,
                icon: Icons.hardware_outlined,
                angle: math.pi * 1.05,
                radius: 92,
                onTap: onStrikeDip,
              ),
              _RadialSatellite(
                label: s.map_radial_sampling,
                icon: Icons.explore_outlined,
                angle: math.pi * 0.82,
                radius: 98,
                onTap: onSampling,
              ),
              _RadialSatellite(
                label: s.map_radial_field_notes,
                icon: Icons.mic_rounded,
                angle: math.pi * 1.18,
                radius: 98,
                onTap: onFieldNotes,
              ),
              _RadialSatellite(
                label: s.map_radial_project_layers,
                icon: Icons.folder_special_outlined,
                angle: math.pi * 1.32,
                radius: 88,
                onTap: onProjectLayers,
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: _MainProHub(
                  trackActive: trackOn,
                  labels: s,
                  onProTools: onProTools,
                  onToggleTrack: () async {
                    HapticFeedback.mediumImpact();
                    if (trackOn) {
                      await trackSvc.stopTracking();
                      return;
                    }
                    final name = 'Trek-${DateTime.now().toIso8601String().substring(0, 19)}'.replaceAll(':', '.');
                    await trackSvc.startTracking(name);
                    if (!context.mounted) return;
                    if (!trackSvc.isTracking) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.track_start_failed), behavior: SnackBarBehavior.floating),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(s.tracking_started_snack), behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RadialSatellite extends StatelessWidget {
  final String label;
  final IconData icon;
  final double angle;
  final double radius;
  final VoidCallback onTap;

  const _RadialSatellite({
    required this.label,
    required this.icon,
    required this.angle,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final x = radius * math.cos(angle);
    final y = radius * math.sin(angle);
    return Positioned(
      right: 36 - x,
      bottom: 40 - y,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: const Color(0xFF1976D2),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.selectionClick();
                onTap();
              },
              child: Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: 72,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.05,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainProHub extends StatelessWidget {
  final bool trackActive;
  final GeoFieldStrings labels;
  final VoidCallback onProTools;
  final Future<void> Function() onToggleTrack;

  const _MainProHub({
    required this.trackActive,
    required this.labels,
    required this.onProTools,
    required this.onToggleTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: Colors.white.withValues(alpha: 0.2),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2196F3).withValues(alpha: 0.55),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: const Color(0xFF1565C0),
                shape: const CircleBorder(),
                elevation: 6,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onProTools();
                  },
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Icon(Icons.settings_rounded, color: Colors.white.withValues(alpha: 0.95), size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                labels.map_ultra_pro_tooltip,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            backgroundColor: Colors.black.withValues(alpha: 0.25),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: onToggleTrack,
          child: Text(
            labels.map_start_stop_tracking,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
