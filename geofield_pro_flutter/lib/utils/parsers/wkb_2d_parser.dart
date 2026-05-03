import 'dart:typed_data';

import 'package:latlong2/latlong.dart';

import '../../models/boundary_polygon.dart';

/// WGS-84 2D WKB — Z/M tark etiladi (2D o‘qiladi).
class Wkb2dParser {
  static bool looksLikeWkb(Uint8List b, int start) {
    if (b.length < start + 5) return false;
    final o = b[start];
    if (o != 0 && o != 1) return false;
    final le = o == 1;
    final t = le
        ? ByteData.sublistView(b, start + 1).getUint32(0, Endian.little)
        : ByteData.sublistView(b, start + 1).getUint32(0, Endian.big);
    final base = t % 1000;
    return base >= 1 && base <= 7;
  }

  static List<BoundaryPolygon> toBoundaries(
    Uint8List b,
    int start,
    String name,
    String sourceFile, {
    ZoneType zone = ZoneType.workArea,
  }) {
    if (b.length < start + 5) return [];
    try {
      final r = _Reader(b, start);
      return _readGeometry(
        r,
        r.readType(),
        name,
        sourceFile,
        zone: zone,
      );
    } catch (_) {
      return const [];
    }
  }

  static List<BoundaryPolygon> _readGeometry(
    _Reader r,
    int type,
    String name,
    String sourceFile, {
    required ZoneType zone,
  }) {
    final base = type % 1000;
    switch (base) {
      case 1:
        r.readPoint2d();
        return const [];
      case 2:
        final line = r.readLineString2d();
        if (line.length < 2) return const [];
        return [
          _linePoly(name, line, sourceFile, ZoneType.base),
        ];
      case 3:
        final poly = r.readPolygon2d();
        if (poly.isEmpty) return const [];
        return [
          _ringPoly(
            name,
            poly[0],
            sourceFile,
            zone: zone,
            description: 'WKB Polygon: $sourceFile',
          ),
        ];
      case 4:
        final n = r.readUint32();
        for (var i = 0; i < n; i++) {
          final off = r.byteOffset();
          if (off >= r.bytes.length) break;
          final sub = _Reader(r.bytes, off);
          final t = sub.readType();
          if (t % 1000 == 1) {
            sub.readPoint2d();
          }
          r.setByteOffset(sub.byteOffset());
        }
        return const [];
      case 5:
        final m = r.readUint32();
        final out = <BoundaryPolygon>[];
        for (var k = 0; k < m; k++) {
          final off = r.byteOffset();
          final sub = _Reader(r.bytes, off);
          final t = sub.readType();
          if (t % 1000 == 2) {
            final line = sub.readLineString2d();
            r.setByteOffset(sub.byteOffset());
            if (line.length >= 2) {
              out.add(
                _linePoly(
                  m == 1 ? name : '$name (Line $k)',
                  line,
                  sourceFile,
                  ZoneType.base,
                ),
              );
            }
          } else {
            break;
          }
        }
        return out;
      case 6:
        final pCount = r.readUint32();
        final out = <BoundaryPolygon>[];
        for (var i = 0; i < pCount; i++) {
          final off = r.byteOffset();
          if (off >= r.bytes.length) break;
          final sub = _Reader(r.bytes, off);
          final t = sub.readType();
          if (t % 1000 == 3) {
            final poly = sub.readPolygon2d();
            r.setByteOffset(sub.byteOffset());
            if (poly.isNotEmpty) {
              out.add(
                _ringPoly(
                  pCount == 1 ? name : '$name ($i)',
                  poly[0],
                  sourceFile,
                  zone: zone,
                  description: 'WKB MPolygon: $sourceFile',
                ),
              );
            }
          } else {
            break;
          }
        }
        return out;
      case 7:
        return const [];
      default:
        return const [];
    }
  }

  static BoundaryPolygon _linePoly(
    String name,
    List<LatLng> pts,
    String source,
    ZoneType z,
  ) {
    return BoundaryPolygon(
      name: '$name (Line)',
      points: pts,
      sourceFile: source,
      description: 'WKB: $source',
      zoneType: z,
    );
  }

  static BoundaryPolygon _ringPoly(
    String name,
    List<LatLng> ring,
    String source, {
    required ZoneType zone,
    String? description,
  }) {
    return BoundaryPolygon(
      name: name,
      points: ring,
      sourceFile: source,
      description: description ?? 'WKB',
      zoneType: zone,
    );
  }
}

class _Reader {
  _Reader(this.bytes, this._start) {
    if (_start >= bytes.length) throw FormatException('WKB start');
    final o = bytes[_start];
    if (o != 0 && o != 1) throw FormatException('WKB order');
    _le = o == 1;
    _o = _start + 1;
    if (_o + 4 > bytes.length) throw FormatException('WKB type');
  }

  final Uint8List bytes;
  final int _start;
  late final bool _le;
  int _o = 0;

  /// Tashqi [Multi*] o‘qishga sinxronlash.
  int byteOffset() => _o;

  void setByteOffset(int v) {
    _o = v;
  }

  int readType() {
    return _readUint32();
  }

  int _readUint32() {
    if (_o + 4 > bytes.length) throw FormatException('WKB u32');
    final v = _le
        ? ByteData.sublistView(bytes, _o).getUint32(0, Endian.little)
        : ByteData.sublistView(bytes, _o).getUint32(0, Endian.big);
    _o += 4;
    return v;
  }

  double _readDouble() {
    if (_o + 8 > bytes.length) throw FormatException('WKB f64');
    final v = _le
        ? ByteData.sublistView(bytes, _o).getFloat64(0, Endian.little)
        : ByteData.sublistView(bytes, _o).getFloat64(0, Endian.big);
    _o += 8;
    return v;
  }

  LatLng readPoint2d() {
    final x = _readDouble();
    final y = _readDouble();
    return LatLng(y, x);
  }

  int readUint32() => _readUint32();

  List<LatLng> readLineString2d() {
    final n = readUint32();
    final o = <LatLng>[];
    for (var i = 0; i < n; i++) {
      o.add(readPoint2d());
    }
    return o;
  }

  /// Har bir halqa: faqat 2D; birinchi — tashqi.
  List<List<LatLng>> readPolygon2d() {
    final nR = readUint32();
    if (nR < 1) return [];
    final rings = <List<LatLng>>[];
    for (var r = 0; r < nR; r++) {
      final n = readUint32();
      final ring = <LatLng>[];
      for (var i = 0; i < n; i++) {
        ring.add(readPoint2d());
      }
      rings.add(ring);
    }
    return rings;
  }
}

/// GeoPackage BLOB: WKB qayerdan boshlangani noma’lum — bir nechta ofset sinovlari.
List<BoundaryPolygon> wkbOrGpkgPayloadToBoundaries(
  Uint8List blob,
  String name,
  String sourceFile, {
  ZoneType zone = ZoneType.workArea,
}) {
  const tried = <int>[
    8,
    12,
    16,
    20,
    24,
    32,
    40,
    48,
    56,
    64,
    72,
    8 + 32,
    8 + 48,
    0
  ];
  for (final off in tried) {
    if (off < 0 || off >= blob.length) continue;
    if (!Wkb2dParser.looksLikeWkb(blob, off)) continue;
    final p = Wkb2dParser.toBoundaries(
      blob,
      off,
      name,
      sourceFile,
      zone: zone,
    );
    if (p.isNotEmpty) return p;
  }
  return const [];
}
