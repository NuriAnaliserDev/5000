import '../models/station.dart';
import '../models/measurement.dart';

/// Geologik ma'lumot kiritish validator — professional quality gate.
///
/// Ma'lumot saqlanmasdan oldin qat'iy tekshiriladi. Xato bo'lsa — String xabar;
/// OK bo'lsa — `null`. Bu qoidalar QField va FieldMove bilan muvofiq.
class GeologyValidator {
  /// Avtomatik xatolarga ruxsat beriladigan GPS accuracy chegarasi (metr).
  /// Professional geologik ish uchun 30m dan yaxshi bo'lmasligi kerak.
  static const double maxAcceptableGpsAccuracy = 30.0;

  /// Altitude chegaralari: -500m (eng chuqur kon) .. 9000m (Everest+).
  static const double minAltitude = -500.0;
  static const double maxAltitude = 9000.0;

  /// Strike va Dip Direction orasida maksimal muvofiqsizlik (daraja).
  /// Right-hand rule: DD ≈ strike + 90 ± 180.
  static const double maxStrikeDipDirMismatch = 5.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // STATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stansiya ma'lumotlarini to'liq tekshiradi. Agar xato bo'lsa, matn
  /// xabar qaytaradi; OK bo'lsa — null.
  static String? validateStation(Station s) {
    // 1. Nomi bo'sh bo'lmasligi shart
    if (s.name.trim().isEmpty) {
      return 'Stansiya nomi bo\'sh bo\'lishi mumkin emas!';
    }

    // 2. Dip 0-90°
    if (s.dip < 0 || s.dip > 90) {
      return 'Dip burchagi 0° va 90° oralig\'ida bo\'lishi shart!';
    }

    // 3. Strike 0-360°
    if (s.strike < 0 || s.strike >= 360) {
      return 'Strike burchagi 0° va 360° oralig\'ida bo\'lishi shart!';
    }

    // 4. Dip Direction (agar qo'yilgan bo'lsa) 0-360°
    if (s.dipDirection != null &&
        (s.dipDirection! < 0 || s.dipDirection! >= 360)) {
      return 'Dip Direction 0° va 360° oralig\'ida bo\'lishi shart!';
    }

    // 5. Strike ↔ Dip Direction izchilligi (right-hand rule)
    if (s.dipDirection != null && s.dip > 1) {
      final expected = (s.strike + 90) % 360;
      double diff = (s.dipDirection! - expected).abs();
      if (diff > 180) diff = 360 - diff;
      if (diff > maxStrikeDipDirMismatch) {
        return 'Strike (${s.strike.toStringAsFixed(0)}°) va Dip Direction '
            '(${s.dipDirection!.toStringAsFixed(0)}°) muvofiq emas. '
            'Kutilgan: ${expected.toStringAsFixed(0)}°';
      }
    }

    // 6. Balandlik oralig'i
    if (s.altitude < minAltitude || s.altitude > maxAltitude) {
      return 'Balandlik oraliqdan tashqari (-500..9000 m).';
    }

    // 7. GPS koordinatalari — 0,0 odatda xato
    if (s.lat == 0 && s.lng == 0) {
      return 'GPS koordinatalari (0°, 0°) bo\'lishi mumkin emas!';
    }

    // 8. Lat/Lng chegaralari
    if (s.lat < -90 || s.lat > 90) {
      return 'Kenglik (Lat) -90° va +90° oralig\'ida bo\'lishi shart!';
    }
    if (s.lng < -180 || s.lng > 180) {
      return 'Uzunlik (Lng) -180° va +180° oralig\'ida bo\'lishi shart!';
    }

    // 9. Measurements ichidagi ro'yxat — har birini tekshirish
    if (s.measurements != null) {
      for (int i = 0; i < s.measurements!.length; i++) {
        final err = validateMeasurement(s.measurements![i]);
        if (err != null) {
          return 'O\'lchov #${i + 1}: $err';
        }
      }
    }

    return null;
  }

  /// GPS aniqligi ogohlantirish — block emas, lekin foydalanuvchiga
  /// "aniqligingiz past" deb ko'rsatish uchun.
  /// Returns: ogohlantirish matni yoki null.
  static String? warnLowGpsAccuracy(double? accuracy) {
    if (accuracy == null) return null;
    if (accuracy > maxAcceptableGpsAccuracy) {
      return 'GPS aniqligi past (±${accuracy.toStringAsFixed(1)}m). '
          'Ochiq joyga chiqib qayta tekshiring.';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MEASUREMENT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Bitta measurement validatsiyasi.
  static String? validateMeasurement(Measurement m) {
    if (m.dip < 0 || m.dip > 90) {
      return 'Dip burchagi 0-90° oralig\'ida bo\'lishi shart!';
    }
    if (m.strike < 0 || m.strike >= 360) {
      return 'Strike burchagi 0-360° oralig\'ida bo\'lishi shart!';
    }
    if (m.dipDirection < 0 || m.dipDirection >= 360) {
      return 'Dip Direction 0-360° oralig\'ida bo\'lishi shart!';
    }
    const validTypes = {
      'bedding',
      'cleavage',
      'lineation',
      'joint',
      'contact',
      'fault',
      'other'
    };
    if (!validTypes.contains(m.type)) {
      return 'Noto\'g\'ri measurement type: ${m.type}';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MINE REPORT
  // ═══════════════════════════════════════════════════════════════════════════

  static String? validateMineData(Map<String, dynamic> data) {
    final depth = double.tryParse(data['depth']?.toString() ?? '0') ?? 0;
    if (depth < 0) {
      return 'Chuqurlik (Depth) manfiy bo\'lishi mumkin emas!';
    }
    if (depth > 10000) {
      return 'Chuqurlik 10000m dan katta bo\'lishi mumkin emas (yana tekshiring).';
    }

    final totalLoads =
        int.tryParse(data['total_loads']?.toString() ?? '1') ?? 1;
    if (totalLoads <= 0) {
      return 'Reyslar soni kamida 1 ta bo\'lishi shart!';
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SAMPLE ID UNIQUENESS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Berilgan stansiyalar ro'yxatida sampleId takrorlanishi bo'lsa —
  /// qaytaradi. Professional geologik laboratoriyalar duplikatni qabul
  /// qilmaydi.
  static String? findDuplicateSampleId(List<Station> stations,
      {String? excludeName}) {
    final seen = <String, String>{};
    for (final s in stations) {
      if (excludeName != null && s.name == excludeName) continue;
      final sid = s.sampleId?.trim();
      if (sid == null || sid.isEmpty) continue;
      if (seen.containsKey(sid)) {
        return 'Sample ID "$sid" takrorlangan: "${seen[sid]}" va "${s.name}"';
      }
      seen[sid] = s.name;
    }
    return null;
  }
}
