import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/station.dart';
import '../../models/track_data.dart';

/// WGS84 shapefile: `stations` (Point) + har bir `track` (Polyline), ZIP.
class ShapefileWriter {
  static const _wgs84Wkt =
      'GEOGCS["WGS 84",DATUM["WGS_1984",SPHEROID["WGS 84",6378137,298.257223563]],'
      'PRIMEM["Greenwich",0],UNIT["degree",0.0174532925199433]]';

  static Future<File> writeZip({
    required List<Station> stations,
    required List<TrackData> tracks,
  }) async {
    final tmp = await getTemporaryDirectory();
    final path =
        '${tmp.path}/geofield_shp_${DateTime.now().millisecondsSinceEpoch}.zip';
    final o = <String, List<int>>{};

    if (stations.isNotEmpty) {
      _points('stations', stations, o);
    }
    for (var i = 0; i < tracks.length; i++) {
      final t = tracks[i];
      if (t.points.length < 2) continue;
      _line('track_${i + 1}_${_n(t.name)}', t, o);
    }
    if (o.isEmpty) {
      return File(path)..writeAsBytesSync(ZipEncoder().encode(Archive())!);
    }
    final a = Archive();
    o.forEach((k, v) => a.addFile(ArchiveFile(k, v.length, v)));
    return File(path)..writeAsBytesSync(ZipEncoder().encode(a)!);
  }

  static String _n(String s) {
    if (s.isEmpty) return 'line';
    return s
        .replaceAll(RegExp(r'[^\w\-\s]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
  }

  static void _points(String base, List<Station> s, Map<String, List<int>> o) {
    var minX = s.first.lng, maxX = s.first.lng, minY = s.first.lat, maxY = s.first.lat;
    for (final x in s) {
      if (x.lng < minX) minX = x.lng;
      if (x.lng > maxX) maxX = x.lng;
      if (x.lat < minY) minY = x.lat;
      if (x.lat > maxY) maxY = x.lat;
    }
    final r = s.map((e) => _pt(e.lng, e.lat)).toList();
    o['$base.shp'] = _shp(1, minX, minY, maxX, maxY, r);
    o['$base.shx'] = _shx(1, minX, minY, maxX, maxY, r);
    o['$base.dbf'] = _dbf(s.map((e) => e.name).toList(), 100);
    o['$base.prj'] = utf8.encode(_wgs84Wkt);
  }

  static void _line(String base, TrackData t, Map<String, List<int>> o) {
    final p = t.points;
    var minX = p.first.lng, maxX = p.first.lng, minY = p.first.lat, maxY = p.first.lat;
    for (final q in p) {
      if (q.lng < minX) minX = q.lng;
      if (q.lng > maxX) maxX = q.lng;
      if (q.lat < minY) minY = q.lat;
      if (q.lat > maxY) maxY = q.lat;
    }
    final r = [_pl(p)];
    o['$base.shp'] = _shp(3, minX, minY, maxX, maxY, r);
    o['$base.shx'] = _shx(3, minX, minY, maxX, maxY, r);
    o['$base.dbf'] = _dbf([t.name], 200);
    o['$base.prj'] = utf8.encode(_wgs84Wkt);
  }

  static Uint8List _pt(double x, double y) {
    final d = ByteData(20);
    d.setInt32(0, 1, Endian.little);
    d.setFloat64(4, x, Endian.little);
    d.setFloat64(12, y, Endian.little);
    return d.buffer.asUint8List();
  }

  static Uint8List _pl(List<TrackPoint> pts) {
    final n = pts.length;
    var minX = pts.first.lng, maxX = pts.first.lng, minY = pts.first.lat, maxY = pts.first.lat;
    for (final q in pts) {
      if (q.lng < minX) minX = q.lng;
      if (q.lng > maxX) maxX = q.lng;
      if (q.lat < minY) minY = q.lat;
      if (q.lat > maxY) maxY = q.lat;
    }
    final len = 4 + 32 + n * 16;
    final d = ByteData(len);
    d.setInt32(0, 3, Endian.little);
    d.setFloat64(4, minX, Endian.little);
    d.setFloat64(12, minY, Endian.little);
    d.setFloat64(20, maxX, Endian.little);
    d.setFloat64(28, maxY, Endian.little);
    d.setInt32(36, 1, Endian.little);
    d.setInt32(40, n, Endian.little);
    d.setInt32(44, 0, Endian.little);
    var o = 48;
    for (final q in pts) {
      d.setFloat64(o, q.lng, Endian.little);
      o += 8;
      d.setFloat64(o, q.lat, Endian.little);
      o += 8;
    }
    return d.buffer.asUint8List(0, len);
  }

  static Uint8List _shp(
    int t,
    double x0,
    double y0,
    double x1,
    double y1,
    List<Uint8List> c,
  ) {
    final sb = BytesBuilder();
    for (var i = 0; i < c.length; i++) {
      final w = c[i].lengthInBytes >> 1;
      final h = ByteData(8);
      h.setInt32(0, i + 1, Endian.big);
      h.setInt32(4, w, Endian.big);
      sb.add(h.buffer.asUint8List());
      sb.add(c[i]);
    }
    final b = sb.toBytes();
    final h = _hd(t, x0, y0, x1, y1, 100 + b.length);
    return Uint8List.fromList([...h, ...b]);
  }

  static Uint8List _shx(
    int t,
    double x0,
    double y0,
    double x1,
    double y1,
    List<Uint8List> c,
  ) {
    // Offset — .shp fayl boshidan 16-bit so‘zlar, birinchi yozuv 100-baytda → 50.
    var of = 50;
    final ib = BytesBuilder();
    for (final x in c) {
      final w = x.lengthInBytes >> 1;
      final p = ByteData(8);
      p.setInt32(0, of, Endian.big);
      p.setInt32(4, w, Endian.big);
      of += 4 + w; // 8-bayt yozuv sarlavhasi = 4 so‘z + tarkib
      ib.add(p.buffer.asUint8List());
    }
    final i = ib.toBytes();
    final h = _hd(t, x0, y0, x1, y1, 100 + i.length);
    return Uint8List.fromList([...h, ...i]);
  }

  static Uint8List _hd(
    int t,
    double x0,
    double y0,
    double x1,
    double y1,
    int bLen,
  ) {
    final d = ByteData(100);
    d.setInt32(0, 9994, Endian.big);
    d.setInt32(24, bLen >> 1, Endian.big);
    d.setInt32(28, 1000, Endian.little);
    d.setInt32(32, t, Endian.little);
    d.setFloat64(36, x0, Endian.little);
    d.setFloat64(44, y0, Endian.little);
    d.setFloat64(52, x1, Endian.little);
    d.setFloat64(60, y1, Endian.little);
    d.setFloat64(68, 0, Endian.little);
    d.setFloat64(76, 0, Endian.little);
    d.setFloat64(84, 0, Endian.little);
    d.setFloat64(92, 0, Endian.little);
    return d.buffer.asUint8List();
  }

  static Uint8List _dbf(List<String> rows, int w) {
    const hl = 96;
    final fLen = w.clamp(1, 254);
    final rLen = 1 + fLen;
    final h = ByteData(hl);
    h.setUint8(0, 0x03);
    final d = DateTime.now().toUtc();
    h.setUint8(1, d.year - 1900);
    h.setUint8(2, d.month);
    h.setUint8(3, d.day);
    h.setInt32(4, rows.length, Endian.little);
    h.setInt16(8, hl, Endian.little);
    h.setInt16(10, rLen, Endian.little);
    for (var i = 12; i < 32; i++) {
      h.setUint8(i, 0);
    }
    const n = 'NAME';
    for (var i = 0; i < n.length; i++) {
      h.setUint8(32 + i, n.codeUnitAt(i));
    }
    h.setUint8(32 + 11, 0x43);
    h.setInt32(32 + 12, 1, Endian.little);
    h.setUint8(32 + 16, fLen);
    h.setUint8(32 + 17, 0);
    for (var i = 32 + 18; i < 64; i++) {
      h.setUint8(i, 0);
    }
    h.setUint8(64, 0x0D);
    for (var i = 65; i < hl; i++) {
      h.setUint8(i, 0);
    }
    final b = BytesBuilder()..add(h.buffer.asUint8List());
    for (final r0 in rows) {
      var t = r0;
      if (t.length > fLen) {
        t = t.substring(0, fLen);
      }
      b.addByte(0x20);
      for (var i = 0; i < fLen; i++) {
        if (i < t.length) {
          final c = t.codeUnitAt(i);
          b.addByte((c < 0x20 || c > 0x7E) ? 0x3F : c);
        } else {
          b.addByte(0x20);
        }
      }
    }
    return b.toBytes();
  }
}
