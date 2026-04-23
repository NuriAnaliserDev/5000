import 'dart:io';
import 'dart:math' as math;

import 'package:path_provider/path_provider.dart';

import '../../models/station.dart';
import '../../models/track_data.dart';
import '../../utils/geo/utm_coord.dart';

/// AutoCAD R12/R14 DXF: HEADER, TABLES (LAYER), ENTITIES. UTM (metr) yoki WGS84.
class DxfWriter {
  static Future<File> write({
    required List<Station> stations,
    required List<TrackData> tracks,
    bool useUtm = true,
    String? fileName,
  }) async {
    final directory = await getTemporaryDirectory();
    final name = fileName ??
        'geofield_export_${DateTime.now().millisecondsSinceEpoch}.dxf';
    final file = File('${directory.path}/$name');
    return file.writeAsString(
      buildString(stations: stations, tracks: tracks, useUtm: useUtm),
    );
  }

  static String buildString({
    required List<Station> stations,
    required List<TrackData> tracks,
    bool useUtm = true,
  }) {
    final b = StringBuffer();
    _writeHeader(b);
    _writeTables(b);
    _writeEntities(b, stations, tracks, useUtm: useUtm);
    b.writeln('  0\nEOF');
    return b.toString();
  }

  static void _writeHeader(StringBuffer b) {
    b.writeln('  0\nSECTION\n  2\nHEADER');
    b.writeln('  9\n\$ACADVER\n  1\nAC1009');
    b.writeln('  9\n\$INSBASE\n 10\n0.0\n 20\n0.0\n 30\n0.0');
    b.writeln('  9\n\$EXTMIN\n 10\n0.0\n 20\n0.0\n 30\n0.0');
    b.writeln('  9\n\$EXTMAX\n 10\n1.0\n 20\n1.0\n 30\n0.0');
    b.writeln('  9\n\$LIMMIN\n 10\n0.0\n 20\n0.0');
    b.writeln('  9\n\$LIMMAX\n 10\n1.0\n 20\n1.0');
    b.writeln('  0\nENDSEC');
  }

  static void _writeTables(StringBuffer b) {
    b.writeln('  0\nSECTION\n  2\nTABLES');
    b.writeln('  0\nTABLE\n  2\nLAYER\n 70\n3');
    _writeLayer(b, 'Stations', 2);
    _writeLayer(b, 'Tracks', 3);
    _writeLayer(b, 'StrikeDip', 1);
    b.writeln('  0\nENDTAB');
    b.writeln('  0\nENDSEC');
  }

  static void _writeLayer(StringBuffer b, String name, int colorIndex) {
    b.writeln('  0\nLAYER');
    b.writeln('  2\n$name');
    b.writeln(' 70\n0');
    b.writeln(' 62\n$colorIndex');
    b.writeln('  6\nCONTINUOUS');
  }

  static void _writeEntities(
    StringBuffer b,
    List<Station> stations,
    List<TrackData> tracks, {
    required bool useUtm,
  }) {
    b.writeln('  0\nSECTION\n  2\nENTITIES');

    for (final s in stations) {
      final xy = _project(s.lat, s.lng, useUtm);
      if (xy == null) continue;
      _writePoint(b, 'Stations', xy.$1, xy.$2, s.altitude);
      _writeText(b, 'Stations', xy.$1 + 2, xy.$2 + 2, s.name, height: 2.0);
      if (s.strike != 0 || s.dip != 0) {
        _writeStrikeDipTick(b, xy.$1, xy.$2, s.strike, s.dip);
      }
    }

    for (final t in tracks) {
      if (t.points.isEmpty) continue;
      final projected = <(double, double)>[];
      for (final p in t.points) {
        final xy = _project(p.lat, p.lng, useUtm);
        if (xy != null) projected.add(xy);
      }
      if (projected.length < 2) continue;
      _writeLwPolyline(b, 'Tracks', projected);
    }

    b.writeln('  0\nENDSEC');
  }

  static (double, double)? _project(double lat, double lng, bool useUtm) {
    if (!useUtm) return (lng, lat);
    final u = UtmCoord.fromLatLng(lat, lng);
    if (!u.isValid) return null;
    return (u.easting, u.northing);
  }

  static void _writePoint(
    StringBuffer b,
    String layer,
    double x,
    double y,
    double z,
  ) {
    b.writeln('  0\nPOINT');
    b.writeln('  8\n$layer');
    b.writeln(' 10\n$x');
    b.writeln(' 20\n$y');
    b.writeln(' 30\n$z');
  }

  static void _writeText(
    StringBuffer b,
    String layer,
    double x,
    double y,
    String text, {
    double height = 1.0,
  }) {
    b.writeln('  0\nTEXT');
    b.writeln('  8\n$layer');
    b.writeln(' 10\n$x');
    b.writeln(' 20\n$y');
    b.writeln(' 40\n$height');
    b.writeln('  1\n${_escape(text)}');
  }

  static void _writeLwPolyline(
    StringBuffer b,
    String layer,
    List<(double, double)> points,
  ) {
    b.writeln('  0\nLWPOLYLINE');
    b.writeln('  8\n$layer');
    b.writeln(' 90\n${points.length}');
    b.writeln(' 70\n0');
    for (final p in points) {
      b.writeln(' 10\n${p.$1}');
      b.writeln(' 20\n${p.$2}');
    }
  }

  static void _writeStrikeDipTick(
    StringBuffer b,
    double x,
    double y,
    double strike,
    double dip,
  ) {
    const half = 2.0;
    final rad = (90.0 - strike) * math.pi / 180.0;
    final dx = half * math.cos(rad);
    final dy = half * math.sin(rad);
    _writeLine(b, 'StrikeDip', x - dx, y - dy, x + dx, y + dy);
    final tickLen = 1.0 * (dip.abs() / 90.0).clamp(0.2, 1.0);
    final px = tickLen * math.cos(rad + math.pi / 2);
    final py = tickLen * math.sin(rad + math.pi / 2);
    _writeLine(b, 'StrikeDip', x, y, x + px, y + py);
  }

  static void _writeLine(
    StringBuffer b,
    String layer,
    double x1,
    double y1,
    double x2,
    double y2,
  ) {
    b.writeln('  0\nLINE');
    b.writeln('  8\n$layer');
    b.writeln(' 10\n$x1');
    b.writeln(' 20\n$y1');
    b.writeln(' 11\n$x2');
    b.writeln(' 21\n$y2');
  }

  static String _escape(String s) {
    return s.replaceAll('^', '^^').replaceAll('\n', '\\P').replaceAll('\r', '');
  }
}
