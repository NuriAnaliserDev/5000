import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geofield_pro_flutter/models/station.dart';
import 'package:geofield_pro_flutter/models/track_data.dart';
import 'package:geofield_pro_flutter/services/export/shapefile_writer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const ch = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(ch, (call) async {
      if (call.method == 'getTemporaryDirectory') {
        return Directory.systemTemp.path;
      }
      return null;
    });
  });

  group('ShapefileWriter.writeZip', () {
    test('bir stansiya — ZIPda stations.shp va .prj', () async {
      final s = Station(
        name: 'T1',
        lat: 41.3,
        lng: 69.2,
        altitude: 400,
        strike: 0,
        dip: 0,
        azimuth: 0,
        date: DateTime.utc(2026, 1, 1),
      );
      final file =
          await ShapefileWriter.writeZip(stations: [s], tracks: const []);
      expect(await file.exists(), isTrue);
      final bytes = await file.readAsBytes();
      final zip = ZipDecoder().decodeBytes(bytes);
      final names = zip.map((f) => f.name).toList();
      expect(names, contains('stations.shp'));
      expect(names, contains('stations.shx'));
      expect(names, contains('stations.dbf'));
      expect(names, contains('stations.prj'));
    });

    test('faqat track — polyline shp', () async {
      final t = TrackData(
        name: 'L1',
        startTime: DateTime.utc(2026, 1, 1),
        points: [
          TrackPoint(
            lat: 41.0,
            lng: 69.0,
            alt: 0,
            time: DateTime.utc(2026),
          ),
          TrackPoint(
            lat: 41.1,
            lng: 69.1,
            alt: 0,
            time: DateTime.utc(2026),
          ),
        ],
        distanceMeters: 0,
      );
      final file =
          await ShapefileWriter.writeZip(stations: const [], tracks: [t]);
      final zip = ZipDecoder().decodeBytes(await file.readAsBytes());
      final names = zip.map((f) => f.name).toList();
      expect(names.any((n) => n.endsWith('.shp') && n.startsWith('track_')),
          isTrue);
    });

    test('bo‘sh — nol hajmli yoki bo‘sh arxiv', () async {
      final file =
          await ShapefileWriter.writeZip(stations: const [], tracks: const []);
      expect(await file.exists(), isTrue);
      final len = await file.length();
      expect(len, greaterThanOrEqualTo(0));
      await file.delete();
    });
  });
}
