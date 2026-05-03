import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_strings.dart';
import '../../../services/track_service.dart';
import '../../../utils/app_localizations.dart';

/// Stitch xarita: yuqorida (GPS osti) yoki pastda — dala menyusi + Ultra Pro.
class MapStitchMapHub extends StatelessWidget {
  const MapStitchMapHub({
    super.key,
    required this.menuOpen,
    required this.onMenuOpenChanged,
    required this.drawTutorialKey,
    required this.followGps,
    required this.onOpenProTools,
    required this.onDraw,
    required this.onAddStation,
    required this.onFollowToggle,
    required this.onMyLocation,
    required this.onStrikeDip,
    required this.onSampling,
    required this.onFieldNotes,
    required this.onProjectLayers,
    required this.onToggleTrack,
    this.anchorTop = false,
  });

  final bool menuOpen;
  final ValueChanged<bool> onMenuOpenChanged;
  final GlobalKey? drawTutorialKey;
  final bool followGps;
  final VoidCallback onOpenProTools;
  final VoidCallback onDraw;
  final VoidCallback onAddStation;
  final VoidCallback onFollowToggle;
  final VoidCallback onMyLocation;
  final VoidCallback onStrikeDip;
  final VoidCallback onSampling;
  final VoidCallback onFieldNotes;
  final VoidCallback onProjectLayers;
  final Future<void> Function() onToggleTrack;

  /// `true` — tugmalar GPS / qidiruv blokining ostida (2-rasmdagi tartib).
  final bool anchorTop;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          anchorTop ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        _MapFieldSpeedDial(
          menuOpen: menuOpen,
          onMenuOpenChanged: onMenuOpenChanged,
          drawTutorialKey: drawTutorialKey,
          followGps: followGps,
          anchorTop: anchorTop,
          onDraw: onDraw,
          onAddStation: onAddStation,
          onFollowToggle: onFollowToggle,
          onMyLocation: onMyLocation,
          onStrikeDip: onStrikeDip,
          onSampling: onSampling,
          onFieldNotes: onFieldNotes,
          onProjectLayers: onProjectLayers,
          onToggleTrack: onToggleTrack,
        ),
        const SizedBox(width: 10),
        _UltraProCornerButton(onTap: onOpenProTools),
      ],
    );
  }
}

class _UltraProCornerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _UltraProCornerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = GeoFieldStrings.of(context);
    return Tooltip(
      message: s?.map_ultra_pro_tooltip ?? 'Pro',
      child: Material(
        color: const Color(0xFF0D47A1),
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: Colors.black45,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              Icons.workspace_premium_rounded,
              color: Colors.amber.shade200,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

enum _DialActionKind {
  plain,
  track,
}

class _DialItem {
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final _DialActionKind kind;

  const _DialItem({
    required this.label,
    required this.icon,
    this.onTap,
    this.kind = _DialActionKind.plain,
  });
}

class _MapFieldSpeedDial extends StatefulWidget {
  const _MapFieldSpeedDial({
    required this.menuOpen,
    required this.onMenuOpenChanged,
    this.drawTutorialKey,
    required this.followGps,
    this.anchorTop = false,
    required this.onDraw,
    required this.onAddStation,
    required this.onFollowToggle,
    required this.onMyLocation,
    required this.onStrikeDip,
    required this.onSampling,
    required this.onFieldNotes,
    required this.onProjectLayers,
    required this.onToggleTrack,
  });

  final bool menuOpen;
  final ValueChanged<bool> onMenuOpenChanged;
  final GlobalKey? drawTutorialKey;
  final bool followGps;
  final bool anchorTop;
  final VoidCallback onDraw;
  final VoidCallback onAddStation;
  final VoidCallback onFollowToggle;
  final VoidCallback onMyLocation;
  final VoidCallback onStrikeDip;
  final VoidCallback onSampling;
  final VoidCallback onFieldNotes;
  final VoidCallback onProjectLayers;
  final Future<void> Function() onToggleTrack;

  @override
  State<_MapFieldSpeedDial> createState() => _MapFieldSpeedDialState();
}

class _MapFieldSpeedDialState extends State<_MapFieldSpeedDial>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _curve = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    if (widget.menuOpen) {
      _ctrl.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant _MapFieldSpeedDial oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.menuOpen != oldWidget.menuOpen) {
      if (widget.menuOpen) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    widget.onMenuOpenChanged(!widget.menuOpen);
  }

  void _closeMenu() {
    if (widget.menuOpen) {
      widget.onMenuOpenChanged(false);
    }
  }

  void _afterCloseSync(VoidCallback fn) {
    _closeMenu();
    Future<void>.delayed(const Duration(milliseconds: 85), () {
      if (mounted) {
        fn();
      }
    });
  }

  Future<void> _afterCloseAsync(Future<void> Function() fn) async {
    _closeMenu();
    await Future<void>.delayed(const Duration(milliseconds: 85));
    if (mounted) {
      await fn();
    }
  }

  List<_DialItem> _buildItems(GeoFieldStrings s, bool trackOn) {
    return [
      _DialItem(
          label: s.layer_drawings, icon: Icons.edit_road, onTap: widget.onDraw),
      _DialItem(
        label: context.loc('new_station_btn'),
        icon: Icons.add_location_alt_outlined,
        onTap: widget.onAddStation,
      ),
      _DialItem(
        label: s.map_follow_gps,
        icon: widget.followGps
            ? Icons.navigation_rounded
            : Icons.wifi_tethering_rounded,
        onTap: widget.onFollowToggle,
      ),
      _DialItem(
        label: s.map_my_location,
        icon: Icons.gps_fixed_rounded,
        onTap: widget.onMyLocation,
      ),
      _DialItem(
        label: s.map_radial_strike_dip,
        icon: Icons.hardware_outlined,
        onTap: widget.onStrikeDip,
      ),
      _DialItem(
        label: s.map_radial_sampling,
        icon: Icons.explore_outlined,
        onTap: widget.onSampling,
      ),
      _DialItem(
        label: s.map_radial_field_notes,
        icon: Icons.mic_rounded,
        onTap: widget.onFieldNotes,
      ),
      _DialItem(
        label: s.map_radial_project_layers,
        icon: Icons.folder_special_outlined,
        onTap: widget.onProjectLayers,
      ),
      _DialItem(
        label: s.map_start_stop_tracking,
        icon: trackOn ? Icons.stop_rounded : Icons.fiber_manual_record,
        kind: _DialActionKind.track,
      ),
    ];
  }

  void _onItemTapped(_DialItem item) {
    HapticFeedback.selectionClick();
    if (item.kind == _DialActionKind.track) {
      unawaited(_afterCloseAsync(widget.onToggleTrack));
      return;
    }
    final t = item.onTap;
    if (t != null) {
      _afterCloseSync(t);
    }
  }

  Widget _body(int i, int n, _DialItem item, double t, bool trackOn) {
    final progress = t.clamp(0.0, 1.0);
    final u = n <= 1 ? 0.5 : i / (n - 1);
    final angle = math.pi * (0.97 - u * 0.48);
    const double r = 120;
    final dx = math.cos(angle) * r * progress;
    final dy = math.sin(angle) * r * progress;
    const double fabR = 28;
    final trackActive = item.kind == _DialActionKind.track && trackOn;
    final radial = IgnorePointer(
      ignoring: progress < 0.08,
      child: Opacity(
        opacity: progress,
        child: Transform.scale(
          scale: 0.5 + 0.5 * progress,
          alignment: Alignment.center,
          child: Tooltip(
            message: item.label,
            child: Material(
              color:
                  trackActive ? Colors.red.shade800 : const Color(0xFF1976D2),
              shape: const CircleBorder(),
              elevation: 3,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _onItemTapped(item),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(item.icon, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.anchorTop) {
      return Positioned(
        right: fabR - dx,
        top: fabR + dy,
        child: radial,
      );
    }
    return Positioned(
      right: fabR - dx,
      bottom: fabR + dy,
      child: radial,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = GeoFieldStrings.of(context);
    if (s == null) {
      return const SizedBox.shrink();
    }
    final trackOn = context.watch<TrackService>().isTracking;
    final actions = _buildItems(s, trackOn);

    return SizedBox(
      width: 268,
      height: 244,
      child: Stack(
        clipBehavior: Clip.none,
        alignment:
            widget.anchorTop ? Alignment.topRight : Alignment.bottomRight,
        children: [
          AnimatedBuilder(
            animation: _curve,
            builder: (context, _) {
              final t = _curve.value.clamp(0.0, 1.0);
              return Stack(
                clipBehavior: Clip.none,
                alignment: widget.anchorTop
                    ? Alignment.topRight
                    : Alignment.bottomRight,
                children: [
                  for (var i = 0; i < actions.length; i++)
                    if (t >= 0.03)
                      _body(i, actions.length, actions[i], t, trackOn),
                ],
              );
            },
          ),
          Positioned(
            right: 0,
            top: widget.anchorTop ? 0 : null,
            bottom: widget.anchorTop ? null : 0,
            child: Material(
              key: widget.drawTutorialKey,
              color: const Color(0xFF1565C0),
              shape: const CircleBorder(),
              elevation: 5,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () {
                  HapticFeedback.selectionClick();
                  _toggleMenu();
                },
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Icon(
                    widget.menuOpen ? Icons.close_rounded : Icons.apps_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
