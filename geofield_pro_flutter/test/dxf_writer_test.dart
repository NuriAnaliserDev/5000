import 'package:flutter_test/flutter_test.dart';
import 'package:geofield_pro_flutter/models/station.dart';
import 'package:geofield_pro_flutter/models/track_data.dart';
import 'package:geofield_pro_flutter/services/export/dxf_writer.dart';

void main() {
  group('DxfWriter.buildString', () {
    Station mk({
      String name = 'S1',
      double lat = 41.30,
      double lng = 69.24,
      double strike = 45,
      double dip = 30,
    }) =>
        Station(
          name: name,
          lat: lat,
          lng: lng,
          altitude: 500,
          strike: strike,
          dip: dip,
          azimuth: 0,
          date: DateTime.utc(2026, 1, 1),
        );

    test('bo‘sh ro‘yxat — faqat HEADER + TABLES + EOF', () {
      final s = DxfWriter.buildString(stations: [], tracks: []);
      expect(s, contains('SECTION'));
      expect(s, contains('HEADER'));
      expect(s, contains('TABLES'));
      expect(s, contains('LAYER'));
      expect(s, contains('Stations'));
      expect(s, contains('Tracks'));
      expect(s, contains('StrikeDip'));
      expect(s, contains('ENTITIES'));
      expect(s.trim().endsWith('EOF'), isTrue);
    });

    test('UTM rejimida koordinatalar metrlarda (>1000)', () {
      final s = DxfWriter.buildString(
        stations: [mk()],
        tracks: [],
        useUtm: true,
      );
      expect(s, contains('POINT'));
      expect(s, contains('TEXT'));
      expect(s, contains('S1'));
      final lines = s.split('\n');
      // 10\n<num> — x koordinata; metr bo‘lganligi sababli ≥ 10000 bo‘ladi.
      var sawBig = false;
      for (var i = 0; i < lines.length - 1; i++) {
        if (lines[i].trim() == '10') {
          final x = double.tryParse(lines[i + 1].trim());
          if (x != null && x.abs() > 10000) {
            sawBig = true;
            break;
          }
        }
      }
      expect(sawBig, isTrue, reason: 'UTM easting > 10k bo‘lishi kerak');
    });

    test('useUtm=false — koordinatalar daraja (kichik sonlar)', () {
      final s = DxfWriter.buildString(
        stations: [mk()],
        tracks: [],
        useUtm: false,
      );
      expect(s, contains('69.24'));
      expect(s, contains('41.3'));
    });

    test('Track ≥2 nuqta → LWPOLYLINE', () {
      final t = TrackData(
        name: 'T1',
        startTime: DateTime.utc(2026, 1, 1),
        points: [
          TrackPoint(lat: 41.0, lng: 69.0, alt: 0, time: DateTime.utc(2026)),
          TrackPoint(lat: 41.1, lng: 69.1, alt: 0, time: DateTime.utc(2026)),
        ],
        distanceMeters: 0,
      );
      final s = DxfWriter.buildString(stations: [], tracks: [t]);
      expect(s, contains('LWPOLYLINE'));
    });

    test('Strike/dip — StrikeDip qatlami chiziladi', () {
      final s = DxfWriter.buildString(stations: [mk()], tracks: []);
      expect(s, contains('StrikeDip'));
      expect(s, contains('LINE'));
    });
  });
}
