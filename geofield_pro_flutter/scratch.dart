import 'package:geofield_pro_flutter/utils/wmm/wmm_model.dart';

void main() {
  final wmm = WmmModel.embedded();
  final dec = wmm.declination(lat: 41.2995, lng: 69.2401, date: DateTime(2025, 1, 1));
  print('Declination: $dec');
  
  final field = wmm.calculate(lat: 41.2995, lng: 69.2401, date: DateTime(2025, 1, 1));
  print('Field dec: ${field.declination}');
}
