import '../models/station.dart';

class GeologyValidator {
  /// Qat'iy mantiqiy qoidalar bo'yicha ma'lumotni tekshirish.
  /// Agar xato bo'lsa, String xabar qaytaradi, aks holda null.
  static String? validateStation(Station s) {
    // 1. Dip (Enish burchagi) 0-90 oralig'ida bo'lishi shart
    if (s.dip < 0 || s.dip > 90) {
      return "Dip burchagi 0° va 90° oralig'ida bo'lishi shart!";
    }

    // 2. Strike/Azimuth 0-360 oralig'ida bo'lishi shart
    if (s.strike < 0 || s.strike >= 360) {
      return "Strike burchagi 0° va 360° oralig'ida bo'lishi shart!";
    }

    // 3. Altitude (Balandlik) o'ta shubhali qiymatlar (bloklash ixtiyoriy lekin tavsiya etiladi)
    if (s.altitude < -430 || s.altitude > 8848) {
      return "Balandlik (Altitude) mantiqsiz qiymatga ega!";
    }

    // 4. Koordinatalar tekshiruvi
    if (s.lat == 0 && s.lng == 0) {
      return "GPS koordinatalari 0 bo'lishi mumkin emas!";
    }

    return null; // Hammasi joyida
  }

  /// Mine Report (Ishlab chiqarish) uchun tekshiruv
  static String? validateMineData(Map<String, dynamic> data) {
    final depth = double.tryParse(data['depth']?.toString() ?? '0') ?? 0;
    if (depth < 0) {
      return "Chuqurlik (Depth) manfiy bo'lishi mumkin emas!";
    }
    
    final totalLoads = int.tryParse(data['total_loads']?.toString() ?? '1') ?? 1;
    if (totalLoads <= 0) {
      return "Reyslar soni kamida 1 ta bo'lishi shart!";
    }

    return null;
  }
}
