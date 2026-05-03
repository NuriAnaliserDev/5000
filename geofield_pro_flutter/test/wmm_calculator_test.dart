import 'package:flutter_test/flutter_test.dart';
import 'package:geofield_pro_flutter/utils/wmm/wmm_model.dart';

void main() {
  test('WMM Calculator for Toshkent', () {
    final wmm = WmmModel.embedded();
    final dec = wmm.declination(
      lat: 41.2995,
      lng: 69.2401,
      date: DateTime(2025, 1, 1),
    );
    expect(dec, greaterThanOrEqualTo(1.0));
    expect(dec, lessThanOrEqualTo(8.0));
  });
}
