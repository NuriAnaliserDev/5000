import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:geofield_pro_flutter/utils/geo/circular_stats.dart';
import 'package:geofield_pro_flutter/utils/geo/geo_constants.dart';
import 'package:geofield_pro_flutter/utils/geo/thickness_calculator.dart';
import 'package:geofield_pro_flutter/utils/geo/utm_coord.dart';
import 'package:geofield_pro_flutter/utils/geology_validator.dart';
import 'package:geofield_pro_flutter/utils/wmm/wmm_model.dart';
import 'package:geofield_pro_flutter/models/measurement.dart';
import 'package:geofield_pro_flutter/models/station.dart';

void main() {
  group('GeoConstants', () {
    test('WGS84 e² = f(2-f)', () {
      final f = GeoConstants.wgs84F;
      expect(GeoConstants.wgs84E2, closeTo(f * (2 - f), 1e-12));
    });

    test('a > b (ellipsoid)', () {
      expect(GeoConstants.wgs84A, greaterThan(GeoConstants.wgs84B));
    });
  });

  group('UtmCoord', () {
    test('kenglik 84° dan yuqorida UTM oraliqdan tashqari', () {
      final u = UtmCoord.fromLatLng(85, 0);
      expect(u.isValid, isFalse);
      expect(u, UtmCoord.outOfRange);
    });

    test('Nyu-York: zona 18N, shimol, easting 500k atrofida (Redfearn)', () {
      final u = UtmCoord.fromLatLng(40.7128, -74.0060);
      expect(u.isValid, isTrue);
      expect(u.zone, 18);
      expect(u.isNorth, isTrue);
      expect(u.easting, inInclusiveRange(580000.0, 590000.0));
      expect(u.northing, inInclusiveRange(4500000.0, 4520000.0));
      expect((u.meridianConvergence).abs(), lessThan(2.0));
      expect(
        u.pointScaleFactor,
        inInclusiveRange(0.9995, 1.0002),
      );
    });

    test('Sidney: 56S, northing 10M+ (janubiy false northing)', () {
      final u = UtmCoord.fromLatLng(-33.8688, 151.2093);
      expect(u.isValid, isTrue);
      expect(u.isNorth, isFalse);
      expect(u.northing, greaterThan(6200000.0));
    });

    test('toMap() va qisqa ko‘rinish', () {
      final u = UtmCoord.fromLatLng(0, 0);
      expect(u.zone, 31);
      expect(u.shortDisplay, contains('31'));
      final m = u.toMap();
      expect(m['zone'], u.zone);
      expect(m['easting'], u.easting);
    });

    test('UTM metr → lat/lng (Toshkent atrofi, teskarilik)', () {
      final u = UtmCoord.fromLatLng(41.3111, 69.2797);
      expect(u.isValid, isTrue);
      final back = UtmCoord.toLatLngFromUtmMeters(
        zone: u.zone,
        easting: u.easting,
        northing: u.northing,
        hintLatitude: 41,
      );
      expect((back.latitude - 41.3111).abs(), lessThan(0.0001));
      expect((back.longitude - 69.2797).abs(), lessThan(0.0001));
    });

    test('UTM metr → lat/lng (Sidney, hintLatitude bilan)', () {
      final u = UtmCoord.fromLatLng(-33.8688, 151.2093);
      expect(u.isValid, isTrue);
      final back = UtmCoord.toLatLngFromUtmMeters(
        zone: u.zone,
        easting: u.easting,
        northing: u.northing,
        hintLatitude: -34,
      );
      expect((back.latitude - (-33.8688)).abs(), lessThan(0.0001));
      expect((back.longitude - 151.2093).abs(), lessThan(0.0001));
    });
  });

  group('ThicknessCalculator', () {
    test('perpendicular: gorizontal yer, W ⊥ strike → W·sin(δ)', () {
      expect(
        ThicknessCalculator.perpendicular(outcropWidth: 10, trueDip: 30),
        closeTo(10 * math.sin(30 * math.pi / 180), 1e-9),
      );
    });

    test('perpendicular: nol kenglik', () {
      expect(
          ThicknessCalculator.perpendicular(outcropWidth: 0, trueDip: 45), 0);
    });

    test('horizontalGround: traverse parallel strike → qalinlik 0', () {
      final t = ThicknessCalculator.horizontalGround(
        outcropWidth: 20,
        trueDip: 60,
        traverseBearing: 45,
        strike: 45,
      );
      expect(t, closeTo(0, 1e-9));
    });

    test('apparentToTrue: ayni dip — koeffitsient 1', () {
      expect(
        ThicknessCalculator.apparentToTrue(
          apparentThickness: 5,
          apparentDip: 40,
          trueDip: 40,
        ),
        closeTo(5, 1e-9),
      );
    });

    test(
        'dippingGround: α=0 — Palmer (cos β) sin δ; horizontalGround esa sin β sin δ',
        () {
      const w = 12.0;
      const d = 35.0;
      const tr = 30.0;
      const st = 0.0;
      const dd = 90.0;
      // β = 30°: Palmer α=0 da TT = W·cos(β)·sin(δ) (belgiga qarab);
      double beta = (tr - st).abs() % 180.0;
      if (beta > 90.0) beta = 180.0 - beta;
      final expected =
          w * math.cos(beta * math.pi / 180) * math.sin(d * math.pi / 180);
      final palmer = ThicknessCalculator.dippingGround(
        outcropWidth: w,
        trueDip: d,
        traverseBearing: tr,
        strike: st,
        slope: 0,
        dipDirection: dd,
      );
      expect(palmer, closeTo(expected, 1e-6));
    });
  });

  group('CircularStats', () {
    test('unimodalMean: 350° va 10° o‘rtachasi 0° atrofida', () {
      final m = CircularStats.unimodalMean([350, 10]);
      expect(m, inInclusiveRange(0.0, 360.0));
      // G‘arb/sharq 0 atrofida
      final diff = math.min((m - 0).abs(), 360 - (m - 0).abs());
      expect(diff, lessThan(1.0));
    });

    test('unimodalResultantLength: bitta yo‘nalish R=1', () {
      expect(
        CircularStats.unimodalResultantLength([45, 45, 45]),
        closeTo(1.0, 1e-9),
      );
    });

    test('axialMean: 10° va 190° bir xil chiziq → ~10°', () {
      final m = CircularStats.axialMean([10, 190]);
      expect(
        m,
        inInclusiveRange(0.0, 180.0),
      );
      expect((m - 10).abs(), lessThan(1.0));
    });

    test('fisher2D: uch parallel azimut ishonchli', () {
      const angles = [12.0, 14.0, 13.0, 12.0, 11.0];
      final s = CircularStats.fisher2D(angles);
      expect(s.n, 5);
      expect(s.isReliable, isTrue);
      expect(s.resultantLength, greaterThan(0.99));
    });

    test('fisher3D: bitta polus — o‘z o‘qida', () {
      final s = CircularStats.fisher3D([
        (dipDir: 90.0, dip: 30.0),
      ]);
      expect(s.n, 1);
      expect(s.resultantLength, 1.0);
    });
  });

  group('WmmModel', () {
    test(
        'declination: hisoblanganda cheksiz emas (model NOAA bilan keyinroq solishtiriladi)',
        () {
      final wmm = WmmModel.embedded();
      final dec = wmm.declination(
        lat: 38.9,
        lng: -77.0,
        date: DateTime.utc(2026, 1, 1),
      );
      expect(dec.isFinite, isTrue);
      expect(dec.abs(), lessThan(180.0));
    });

    test('inclination: shimoliy yarim sharda odatda musbat (pastga)', () {
      final wmm = WmmModel.embedded();
      final f =
          wmm.calculate(lat: 50, lng: 10, date: DateTime.utc(2026, 6, 15));
      expect(f.inclination, inInclusiveRange(40.0, 80.0));
    });

    test('intensivlik: haqiqiy nT oraliqda', () {
      final wmm = WmmModel.embedded();
      final f = wmm.calculate(lat: 0, lng: 0, date: DateTime.utc(2025, 7, 1));
      expect(f.totalIntensity, inInclusiveRange(20000.0, 70000.0));
    });

    test('decimalYil: yil boshida ~YYYY.0', () {
      final t = WmmModel.decimalYear(DateTime.utc(2026, 1, 1));
      expect(t, greaterThan(2025.9));
      expect(t, lessThan(2026.1));
    });

    test('hisob sanasi WMM epoch oralig\'ida (GeoConstants)', () {
      final d = DateTime.utc(2026, 1, 1);
      final y = WmmModel.decimalYear(d);
      expect(
        y,
        inInclusiveRange(
          GeoConstants.wmmEpoch,
          GeoConstants.wmmEpoch + GeoConstants.wmmValidYears,
        ),
      );
    });
  });

  group('GeologyValidator', () {
    Station baseStation() => Station(
          name: 'A1',
          lat: 41.3,
          lng: 69.2,
          altitude: 500,
          strike: 45,
          dip: 30,
          azimuth: 0,
          date: DateTime.now(),
        );

    test('bo‘sh nom', () {
      final s = baseStation().copyWith(name: '   ');
      expect(GeologyValidator.validateStation(s), isNotNull);
    });

    test('to‘g‘ri strike/dip — null (OK)', () {
      final s = baseStation().copyWith(dipDirection: 135);
      expect(GeologyValidator.validateStation(s), isNull);
    });

    test('dip direction strike bilan nomuvofiq', () {
      final s = baseStation().copyWith(dip: 20, dipDirection: 0);
      expect(GeologyValidator.validateStation(s), isNotNull);
    });

    test('(0,0) koordinata rad etiladi', () {
      final s = baseStation().copyWith(lat: 0, lng: 0);
      expect(GeologyValidator.validateStation(s), isNotNull);
    });

    test('warnLowGpsAccuracy: past emas', () {
      expect(GeologyValidator.warnLowGpsAccuracy(5), isNull);
    });

    test('warnLowGpsAccuracy: 40 m ogohlantirish', () {
      final w = GeologyValidator.warnLowGpsAccuracy(40);
      expect(w, isNotNull);
      expect(w, contains('40'));
    });

    test('validateMeasurement: noto‘g‘ri type', () {
      final m = Measurement(
        type: 'invalid_type',
        strike: 0,
        dip: 10,
        dipDirection: 90,
        capturedAt: DateTime.now(),
      );
      expect(GeologyValidator.validateMeasurement(m), isNotNull);
    });

    test('validateMineData: chuqurlik manfiy', () {
      final e = GeologyValidator.validateMineData({'depth': '-1'});
      expect(e, isNotNull);
    });

    test('findDuplicateSampleId: takror', () {
      final a = baseStation().copyWith(name: 'S1', sampleId: 'G-1');
      final b = baseStation().copyWith(name: 'S2', sampleId: 'G-1');
      expect(GeologyValidator.findDuplicateSampleId([a, b]), isNotNull);
    });
  });
}
