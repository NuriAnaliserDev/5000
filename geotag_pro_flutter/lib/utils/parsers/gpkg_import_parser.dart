import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../../models/boundary_polygon.dart';
import 'wkb_2d_parser.dart';

/// GeoPackage (`.gpkg`) — faqat 2D geometriya; WGS-84 baza deb qabul qilinadi.
class GpkgImportParser {
  static Future<List<BoundaryPolygon>> parseFile(String gpkgPath) async {
    final db = await openDatabase(
      gpkgPath,
      readOnly: true,
      singleInstance: true,
    );
    try {
      return await _parseDb(db);
    } finally {
      await db.close();
    }
  }

  static Future<List<BoundaryPolygon>> _parseDb(Database db) async {
    final out = <BoundaryPolygon>[];
    List<Map<String, Object?>> tables;
    try {
      tables = await db.rawQuery(
        "SELECT table_name, column_name "
        "FROM gpkg_geometry_columns "
        "WHERE table_name IS NOT NULL AND column_name IS NOT NULL",
      );
    } catch (_) {
      return const [];
    }
    if (tables.isEmpty) return const [];
    var idx = 0;
    for (final trow in tables) {
      final table = trow['table_name'] as String?;
      final geomCol = trow['column_name'] as String?;
      if (table == null || geomCol == null) continue;
      final safe = table.replaceAll("'", "''");
      List<Map<String, Object?>> features;
      try {
        features = await db.rawQuery('SELECT * FROM "$safe"');
      } catch (_) {
        continue;
      }
      for (final f in features) {
        Object? raw;
        for (final e in f.entries) {
          if (e.key.toLowerCase() == geomCol.toLowerCase()) {
            raw = e.value;
            break;
          }
        }
        final blob = _asBytes(raw);
        if (blob == null || blob.isEmpty) continue;
        idx++;
        var name = 'GPKG $idx';
        for (final k in const ['name', 'Name', 'id', 'ID', 'title', 'label']) {
          if (f.containsKey(k) && f[k] != null) {
            name = f[k]!.toString();
            if (name.isNotEmpty) break;
          }
        }
        out.addAll(
          wkbOrGpkgPayloadToBoundaries(
            blob,
            name,
            'gpkg',
            zone: ZoneType.workArea,
          ),
        );
      }
    }
    return out;
  }

  static Uint8List? _asBytes(Object? v) {
    if (v is Uint8List) return v;
    if (v is List<int>) return Uint8List.fromList(v);
    return null;
  }
}
