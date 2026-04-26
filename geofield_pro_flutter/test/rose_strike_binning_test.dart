import 'package:flutter_test/flutter_test.dart';
import 'package:geofield_pro_flutter/models/station.dart';
import 'package:geofield_pro_flutter/utils/rose_strike_binning.dart';

Station _s(double strike) => Station(
      name: 't',
      lat: 1,
      lng: 1,
      altitude: 0,
      strike: strike,
      dip: 45,
      azimuth: 0,
      date: DateTime(2000),
    );

void main() {
  group('RoseStrikeBinning (audit 2.2.5)', () {
    test('10° va 190° — bir xil yadro bin (16 sektor)', () {
      expect(
        RoseStrikeBinning.halfBinsCore([_s(10)], 16),
        RoseStrikeBinning.halfBinsCore([_s(190)], 16),
      );
      final two = RoseStrikeBinning.halfBinsCore([_s(10), _s(190)], 16);
      final one = RoseStrikeBinning.halfBinsCore([_s(10)], 16);
      expect(
        two.reduce((a, b) => a + b),
        2 * one.reduce((a, b) => a + b),
      );
    });
    test('0°/180°/360° — bir xil', () {
      final b0 = RoseStrikeBinning.halfBinsCore([_s(0)], 16);
      expect(RoseStrikeBinning.halfBinsCore([_s(180)], 16), b0);
      expect(RoseStrikeBinning.halfBinsCore([_s(360)], 16), b0);
    });
    test('8/16/36/72 — 45° va 225° bir xil', () {
      for (final n in [8, 16, 36, 72]) {
        expect(
          RoseStrikeBinning.halfBinsCore([_s(45)], n),
          RoseStrikeBinning.halfBinsCore([_s(225)], n),
        );
      }
    });
    test('fullRingCounts: uzunlik va dublikat', () {
      final core = [1, 2, 0, 0, 0, 0, 0, 0];
      final full = RoseStrikeBinning.fullRingCounts(core, 16);
      expect(full.length, 16);
      expect(full[0], full[8]);
    });
  });
}
