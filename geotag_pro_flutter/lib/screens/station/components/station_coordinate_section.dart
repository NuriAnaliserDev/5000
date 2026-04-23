import 'package:flutter/material.dart';
import '../../../utils/app_localizations.dart';
import '../../../utils/geology_utils.dart';
import '../../../models/station.dart';

class StationCoordinateSection extends StatefulWidget {
  final Station? station;
  final TextEditingController latController;
  final TextEditingController lngController;
  final VoidCallback onUpdateGps;
  final String coordinateFormat;
  final ValueChanged<String> onFormatChanged;

  const StationCoordinateSection({
    super.key,
    required this.station,
    required this.latController,
    required this.lngController,
    required this.onUpdateGps,
    required this.coordinateFormat,
    required this.onFormatChanged,
  });

  @override
  State<StationCoordinateSection> createState() => _StationCoordinateSectionState();
}

class _StationCoordinateSectionState extends State<StationCoordinateSection> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasValidCoords = widget.station != null && 
        !(widget.station!.lat == 0.0 && widget.station!.lng == 0.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          context.loc('geoloc_header').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            letterSpacing: 2,
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            String nextFormat;
                            if (widget.coordinateFormat == 'DD') {
                              nextFormat = 'DMS';
                            } else if (widget.coordinateFormat == 'DMS') {
                              nextFormat = 'UTM';
                            } else {
                              nextFormat = 'DD';
                            }
                            widget.onFormatChanged(nextFormat);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1565C0),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swap_horiz, size: 10, color: Colors.white),
                                const SizedBox(width: 4),
                                Text(
                                  widget.coordinateFormat,
                                  style: const TextStyle(
                                    fontSize: 10, 
                                    color: Colors.white, 
                                    fontWeight: FontWeight.w900, 
                                    letterSpacing: 1
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        hasValidCoords
                            ? (widget.coordinateFormat == 'DD' 
                                ? '${widget.station!.lat.abs().toStringAsFixed(6)}° ${widget.station!.lat >= 0 ? 'N' : 'S'}  ${widget.station!.lng.abs().toStringAsFixed(6)}° ${widget.station!.lng >= 0 ? 'E' : 'W'}'
                                : widget.coordinateFormat == 'DMS'
                                  ? '${GeologyUtils.toDMS(widget.station!.lat, true)}  ${GeologyUtils.toDMS(widget.station!.lng, false)}'
                                  : GeologyUtils.toUTM(widget.station!.lat, widget.station!.lng))
                            : context.loc('no_data'),
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                onPressed: widget.onUpdateGps,
                icon: Icon(Icons.my_location, color: Theme.of(context).colorScheme.secondary, size: 20),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${context.loc('altitude')}: ${widget.station?.altitude.toStringAsFixed(0) ?? '0'} m',
                  style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '±${widget.station?.accuracy?.toStringAsFixed(1) ?? '0'} m',
                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
