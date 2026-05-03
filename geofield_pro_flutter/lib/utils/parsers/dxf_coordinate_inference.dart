import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../../models/boundary_polygon.dart';
import '../geo/geo_constants.dart';
import '../geo/utm_coord.dart';
import '../utm_wgs84.dart';

/// DXF dagi (10/20) juftlari — ko‘pincha WGS-84 emas, UTM yoki mahalliy metr.
/// [hintLat]/[hintLng] — GPS yoki xarita markazi (mahalliy grid uchun majburiy).
class DxfCoordinateInference {
  DxfCoordinateInference._();

  static List<BoundaryPolygon> applyHints(
    List<BoundaryPolygon> polys, {
    double? hintLat,
    double? hintLng,
  }) {
    if (polys.isEmpty) return polys;

    final flat = <LatLng>[];
    for (final p in polys) {
      flat.addAll(p.points);
    }
    if (flat.isEmpty) return polys;

    final toWgs = _buildProjector(flat, hintLat: hintLat, hintLng: hintLng);

    return [
      for (final bp in polys)
        BoundaryPolygon(
          name: bp.name,
          points: [for (final q in bp.points) toWgs(q)],
          sourceFile: bp.sourceFile,
          zoneType: bp.zoneType,
          description: bp.description,
          firestoreId: bp.firestoreId,
          localId: bp.localId,
        ),
    ];
  }

  static LatLng Function(LatLng) _buildProjector(
    List<LatLng> flat, {
    double? hintLat,
    double? hintLng,
  }) {
    if (_looksLikeWgs84(flat)) {
      return (p) => p;
    }
    if (_looksLikeUtm(flat)) {
      final zone = _bestUtmZone(flat, hintLng: hintLng, hintLat: hintLat);
      return (p) => UtmCoord.toLatLngFromUtmMeters(
            zone: zone,
            easting: p.longitude,
            northing: p.latitude,
            hintLatitude: hintLat,
          );
    }
    if (hintLat != null && hintLng != null && _looksLikeLocalMeters(flat)) {
      return (p) => _localMetersToWgs(
            p.longitude,
            p.latitude,
            hintLat,
            hintLng,
          );
    }
    if (hintLng != null && _maybeProjectedLarge(flat)) {
      final zone = UtmWgs84.zoneFromLongitude(hintLng);
      var ok = 0;
      for (final p in flat) {
        final ll = UtmCoord.toLatLngFromUtmMeters(
          zone: zone,
          easting: p.longitude,
          northing: p.latitude,
          hintLatitude: hintLat,
        );
        if (ll.latitude >= GeoConstants.utmMinLat - 2 &&
            ll.latitude <= GeoConstants.utmMaxLat + 2 &&
            ll.longitude >= -180 &&
            ll.longitude <= 180) {
          ok++;
        }
      }
      if (ok >= flat.length * 0.75) {
        return (p) => UtmCoord.toLatLngFromUtmMeters(
              zone: zone,
              easting: p.longitude,
              northing: p.latitude,
              hintLatitude: hintLat,
            );
      }
    }

    return (p) => p;
  }

  static bool _looksLikeWgs84(List<LatLng> pts) {
    if (pts.isEmpty) return false;
    var ok = 0;
    for (final p in pts) {
      if (p.longitude >= -180 &&
          p.longitude <= 180 &&
          p.latitude >= -90 &&
          p.latitude <= 90) {
        ok++;
      }
    }
    return ok >= pts.length * 0.95;
  }

  static bool _looksLikeUtm(List<LatLng> pts) {
    var ok = 0;
    for (final p in pts) {
      final e = p.longitude;
      final n = p.latitude;
      if (e >= 50000 && e <= 940000 && n >= 0 && n <= 19500000) {
        ok++;
      }
    }
    return pts.isNotEmpty && ok >= pts.length * 0.9;
  }

  static bool _maybeProjectedLarge(List<LatLng> pts) {
    var maxV = 0.0;
    for (final p in pts) {
      maxV = math.max(maxV, math.max(p.longitude.abs(), p.latitude.abs()));
    }
    return maxV > 800;
  }

  static bool _looksLikeLocalMeters(List<LatLng> pts) {
    var maxV = 0.0;
    for (final p in pts) {
      maxV = math.max(maxV, math.max(p.longitude.abs(), p.latitude.abs()));
    }
    return maxV >= 10 && maxV < 500000;
  }

  static LatLng _localMetersToWgs(
    double xEastM,
    double yNorthM,
    double hintLat,
    double hintLng,
  ) {
    const mPerDegLat = 111320.0;
    final mPerDegLng =
        111320.0 * math.cos(hintLat * math.pi / 180.0).clamp(0.05, 1.0);
    return LatLng(
      hintLat + yNorthM / mPerDegLat,
      hintLng + xEastM / mPerDegLng,
    );
  }

  static int _bestUtmZone(List<LatLng> pts,
      {double? hintLng, double? hintLat}) {
    if (hintLng != null) {
      return UtmWgs84.zoneFromLongitude(hintLng);
    }
    var sx = 0.0;
    var sy = 0.0;
    for (final p in pts) {
      sx += p.longitude;
      sy += p.latitude;
    }
    final n = pts.length;
    final cx = sx / n;
    final cy = sy / n;

    var bestZ = 35;
    var bestPen = double.infinity;
    for (var z = 1; z <= 60; z++) {
      final ll = UtmCoord.toLatLngFromUtmMeters(
          zone: z, easting: cx, northing: cy, hintLatitude: hintLat);
      var pen = 0.0;
      if (!ll.latitude.isFinite || !ll.longitude.isFinite) {
        pen = 1e12;
      } else {
        if (ll.latitude < GeoConstants.utmMinLat ||
            ll.latitude > GeoConstants.utmMaxLat) {
          pen += 1e6;
        }
        if (ll.longitude < -180 || ll.longitude > 180) {
          pen += 1e6;
        }
      }
      if (pen < bestPen) {
        bestPen = pen;
        bestZ = z;
      }
    }
    return bestZ;
  }
}
