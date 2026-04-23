import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/settings_controller.dart';
import 'geo_field_string_lookup.dart';

String _langCode(String? raw) {
  const ok = ['en', 'tr', 'uz'];
  if (raw == null || raw.isEmpty) return 'en';
  return ok.contains(raw) ? raw : 'en';
}

/// [GeoFieldStrings] + loyiha tili (Hive / [SettingsController]).
/// `trend_recommend_good` / `apparent_result_hint` uchun [GeoFieldStrings]dagi
/// aniqroq [String trend_recommend_good(String dir)] kabi usullarni ishlating.
extension LocalizationExtension on BuildContext {
  String loc(String key) {
    final s = GeoFieldStrings.of(this) ??
        lookupGeoFieldStrings(
            Locale(_langCode(read<SettingsController>().language)));
    return lookupGeoFieldString(s, key) ?? key;
  }

  String locRead(String key) {
    final s = GeoFieldStrings.of(this) ??
        lookupGeoFieldStrings(
            Locale(_langCode(read<SettingsController>().language)));
    return lookupGeoFieldString(s, key) ?? key;
  }
}
