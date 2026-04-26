import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../models/geological_line.dart';
import '../../../utils/linework_utils.dart';

class MapLineworkLayer extends StatelessWidget {
  final List<GeologicalLine> geoLines;
  final bool isDrawingMode;
  final List<LatLng> drawingPoints;
  final String selectedLineType;
  final bool isCurvedMode;

  const MapLineworkLayer({
    super.key,
    required this.geoLines,
    required this.isDrawingMode,
    required this.drawingPoints,
    required this.selectedLineType,
    required this.isCurvedMode,
  });

  @override
  Widget build(BuildContext context) {
    return PolylineLayer(
      polylines: [
        ...geoLines.where((l) => !l.isClosed).expand((l) {
           Color color = l.colorHex != null 
               ? Color(int.parse(l.colorHex!, radix: 16) + 0xFF000000) 
               : Color(int.parse(GeologicalLine.defaultColorHex(l.lineType), radix: 16) + 0xFF000000);
           
           List<LatLng> pts = List.generate(l.lats.length, (i) => LatLng(l.lats[i], l.lngs[i]));
           if (l.isCurved) {
             pts = LineworkUtils.smoothLine(pts);
           }
           
           final List<Polyline> layers = [
             Polyline(
               points: pts,
               color: color,
               strokeWidth: l.strokeWidth,
               pattern: l.isDashed ? StrokePattern.dashed(segments: const [10, 5]) : const StrokePattern.solid(),
             )
           ];
           
           if (l.lineType == 'fault') {
             final teeth = LineworkUtils.calculateThrustTeeth(pts);
             for (final t in teeth) {
               layers.add(Polyline(
                 points: [...t, t.first],
                 color: color,
                 strokeWidth: 2,
               ));
             }
           }
           
           return layers;
        }),
        
        if (isDrawingMode && drawingPoints.isNotEmpty)
          Polyline(
            points: selectedLineType == 'polygon' 
                ? [...(isCurvedMode ? LineworkUtils.smoothLine(drawingPoints) : drawingPoints), (isCurvedMode ? LineworkUtils.smoothLine(drawingPoints) : drawingPoints).first] 
                : (isCurvedMode ? LineworkUtils.smoothLine(drawingPoints) : drawingPoints),
            color: Color(int.parse(GeologicalLine.defaultColorHex(selectedLineType), radix: 16) + 0xFF000000),
            strokeWidth: 3.0,
            pattern: selectedLineType == 'fault' ? StrokePattern.dashed(segments: const [10, 5]) : const StrokePattern.solid(),
          ),
      ],
    );
  }
}
