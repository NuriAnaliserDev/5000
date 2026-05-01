import 'dart:math' as math;

import 'geo_constants.dart';

/// Qatlam qalinligi (bed thickness) uchun turli hisob usullari.
///
/// Yengil xatolar bilan ishlash — geologik xulosada 40% xato berishi mumkin.
/// Bu fayl uch xil klassik formulalarni to'g'ri implementatsiya qiladi:
///
/// 1. **Perpendikulyar kengligidan** (ko'chma chizish joyi strike'ga ⊥ va
///    yer yuzasi gorizontal) → eng oddiy: `TT = W × sin(δ)`.
/// 2. **Arbitrary traverse, horizontal ground** → strike bilan burchak β
///    hisobga olinadi: `TT = W × sin(δ) × sin(β)`.
/// 3. **Dipping/sloping ground** (Palmer 1918 to'liq formula) → traverse
///    yon tomoni α (slope) ham hisobga olinadi.
///
/// Ref: Palmer, H.S. (1918). "New Graphic Method for Determining the Depth
/// and Thickness of Strata and the Projection of Dip". USGS Professional
/// Paper 120-G.
class ThicknessCalculator {
  ThicknessCalculator._();

  /// 1-usul: Gorizontal traverse, strike'ga perpendikulyar.
  ///
  /// Bu eng sodda holat: traverse va strike aynan 90° da, yer yuzasi tekis.
  ///
  /// - [outcropWidth] — yer yuzasidagi qatlamning kengligi (metr).
  /// - [trueDip] — haqiqiy dip burchagi (daraja, 0–90).
  ///
  /// Returns: haqiqiy qalinlik (metr).
  static double perpendicular({
    required double outcropWidth,
    required double trueDip,
  }) {
    if (outcropWidth <= 0) return 0.0;
    final d = trueDip.clamp(0.0, 90.0);
    return outcropWidth * math.sin(d * GeoConstants.degToRad);
  }

  /// 2-usul: Gorizontal traverse, arbitrary azimut.
  ///
  /// Traverse strike'ga ⊥ emas bo'lsa, β burchak — traverse azimut va
  /// strike orasidagi burchak (gorizontal proyeksiyada).
  ///
  /// - [outcropWidth] — yer yuzasidagi kenglik (metr).
  /// - [trueDip] — haqiqiy dip (daraja).
  /// - [traverseBearing] — traverse yo'nalish azimutu (0-360°).
  /// - [strike] — qatlam strike'i (0-360°).
  ///
  /// Returns: haqiqiy qalinlik (metr). β→0 bo'lsa (strike bo'yicha) natija 0.
  static double horizontalGround({
    required double outcropWidth,
    required double trueDip,
    required double traverseBearing,
    required double strike,
  }) {
    if (outcropWidth <= 0) return 0.0;
    // β — strike va traverse orasidagi gorizontal burchak, 0..90°.
    double beta = (traverseBearing - strike).abs() % 180.0;
    if (beta > 90.0) beta = 180.0 - beta;
    final d = trueDip.clamp(0.0, 90.0);
    return outcropWidth *
        math.sin(d * GeoConstants.degToRad) *
        math.sin(beta * GeoConstants.degToRad);
  }

  /// 3-usul: Palmer (1918) — qiyalik (slope) va arbitrary traverse azimuti.
  ///
  /// Yer yuzasi tekis emas va traverse strike'ga ⊥ emas.
  ///
  /// Palmer (1918) — quyidagi ifoda modul bilan qo‘llanadi
  /// (`dippingGround` jismoniy implementatsiyasi):
  ///   TT = |W × (cos β · sin δ · cos α ± sin α · cos δ)|
  /// (yoyilmagan algebraik qisqartirishlardan qoching — chalkashadi).
  ///
  /// - [outcropWidth] W — traverse bo'ylab o'lchangan kenglik (metr).
  /// - [trueDip] δ — haqiqiy dip (daraja).
  /// - [traverseBearing] — traverse azimut (0-360°).
  /// - [strike] — qatlam strike (0-360°).
  /// - [slope] α — traverse slope burchagi (-90..90, pastga tushsa manfiy).
  /// - [dipDirection] — qatlam dip direction (0-360°). Traverse va dip
  ///   bir tomongami yoki qarama-qarshimi — ± belgi aynan shu bog'liq.
  ///
  /// Returns: haqiqiy qalinlik (metr, har doim musbat).
  static double dippingGround({
    required double outcropWidth,
    required double trueDip,
    required double traverseBearing,
    required double strike,
    required double slope,
    required double dipDirection,
  }) {
    if (outcropWidth <= 0) return 0.0;

    final delta = trueDip.clamp(0.0, 90.0) * GeoConstants.degToRad;
    final alpha = slope.clamp(-90.0, 90.0) * GeoConstants.degToRad;

    // β — strike va traverse orasidagi burchak (0..90°).
    double beta = (traverseBearing - strike).abs() % 180.0;
    if (beta > 90.0) beta = 180.0 - beta;
    final betaRad = beta * GeoConstants.degToRad;

    // Traverse va dip direction bir tomonga qaraganmi?
    // Agar bir xil yarim doirada bo'lsa (|diff| < 90°) — bir tomon → "-" belgi
    // (slope down kombinatsiyasi thickness'ni kamaytiradi).
    // Aks holda "+" belgi (traverse dipga qarshi ketadi → slope up).
    final traverseVsDipDiff = (traverseBearing - dipDirection).abs() % 360.0;
    final sameSide = traverseVsDipDiff < 90.0 || traverseVsDipDiff > 270.0;
    final sign = sameSide ? -1.0 : 1.0;

    // Palmer formulasi (unit outcrop width × vektorlar ortogonalligi)
    final tt = outcropWidth *
        (math.cos(betaRad) * math.sin(delta) * math.cos(alpha) +
            sign * math.sin(alpha) * math.cos(delta));
    return tt.abs();
  }

  /// Apparent thickness (agar faqat thickness topilgan bo'lsa, lekin
  /// traverse va strike orasida burchak bor) dan haqiqiy thicknessga
  /// o'tkazish.
  ///
  /// Cheklov: yer yuzasi gorizontal deb hisoblanadi. Dala sharoitida
  /// tepalikda yashagan bo'lsa — [dippingGround] ishlatish kerak.
  static double apparentToTrue({
    required double apparentThickness,
    required double apparentDip,
    required double trueDip,
  }) {
    if (apparentThickness <= 0) return 0.0;
    final aD = apparentDip.clamp(0.0, 90.0) * GeoConstants.degToRad;
    final tD = trueDip.clamp(0.0, 90.0) * GeoConstants.degToRad;
    if (math.sin(tD) == 0) return apparentThickness;
    return apparentThickness * math.sin(aD) / math.sin(tD);
  }
}

/// Thickness traverse holati — UI'da tanlash uchun.
enum ThicknessCase {
  /// Gorizontal traverse strike'ga ⊥.
  perpendicular,

  /// Gorizontal traverse, strike bilan burchak.
  horizontal,

  /// Sloping ground, arbitrary azimut (Palmer).
  dipping,
}
