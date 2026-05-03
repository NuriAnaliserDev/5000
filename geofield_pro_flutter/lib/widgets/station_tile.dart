import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/station.dart';

/// Oddiy, qayta ishlatiladigan Station ro'yxati elementi.
///
/// Dashboard recent stations, search natijalari, arxiv va boshqalar
/// tomonidan ishlatiladi. Faqat UI — logic yo'q.
class StationTile extends StatelessWidget {
  final Station station;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool selectable;

  const StationTile({
    super.key,
    required this.station,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.selectable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF181818) : Colors.white;
    final primary = Theme.of(context).colorScheme.primary;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Material(
      color: selected ? primary.withValues(alpha: 0.12) : surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap ??
            () => Navigator.of(context, rootNavigator: true)
                .pushNamed('/station', arguments: station.key),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              if (selectable)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(
                    selected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    size: 22,
                    color:
                        selected ? primary : onSurface.withValues(alpha: 0.4),
                  ),
                )
              else
                _StationTypeBadge(
                  measurementType: station.measurementType ?? 'bedding',
                ),
              const SizedBox(width: 12),
              Expanded(child: _Info(station: station)),
              _StrikeDipChip(
                strike: station.strike,
                dip: station.dip,
                primary: primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final Station station;
  const _Info({required this.station});

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(station.date);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          station.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          (station.rockType?.isNotEmpty ?? false)
              ? '${station.rockType}  •  $dateStr'
              : dateStr,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${station.lat.toStringAsFixed(5)}, ${station.lng.toStringAsFixed(5)}',
          style: TextStyle(
            fontSize: 10,
            color: onSurface.withValues(alpha: 0.45),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _StrikeDipChip extends StatelessWidget {
  final double strike;
  final double dip;
  final Color primary;

  const _StrikeDipChip({
    required this.strike,
    required this.dip,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${strike.toStringAsFixed(0)}°/${dip.toStringAsFixed(0)}°',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: primary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _StationTypeBadge extends StatelessWidget {
  final String measurementType;
  const _StationTypeBadge({required this.measurementType});

  static const Map<String, IconData> _icons = {
    'bedding': Icons.layers_rounded,
    'cleavage': Icons.vertical_split_rounded,
    'lineation': Icons.timeline_rounded,
    'joint': Icons.border_all_rounded,
    'contact': Icons.compare_arrows_rounded,
    'fault': Icons.broken_image_rounded,
  };

  static const Map<String, Color> _colors = {
    'bedding': Color(0xFF1976D2),
    'cleavage': Color(0xFFFB8C00),
    'lineation': Color(0xFF43A047),
    'joint': Color(0xFF8E24AA),
    'contact': Color(0xFF00ACC1),
    'fault': Color(0xFFE53935),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[measurementType] ?? const Color(0xFF1976D2);
    final icon = _icons[measurementType] ?? Icons.layers_rounded;
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}
