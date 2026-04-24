import '../models/station.dart';

/// Gül diagrammada strike uchun aksial (0..180°) hisob — 10° va 190° bir chiziq.
class RoseStrikeBinning {
  RoseStrikeBinning._();

  /// [binCount] to‘liq aylanadagi sektor soni (8, 16, 36, 72) — juft, ≥2.
  /// Qaytaradi: yarmi (0..binCount/2-1) asosiy sanash; UI to‘liq
  /// [binCount] uzunlikda dublikat qiladi.
  static List<int> halfBinsCore(List<Station> stations, int binCount) {
    final half = binCount ~/ 2;
    if (half < 1) {
      return <int>[0];
    }
    final w = 180.0 / half;
    final core = List<int>.filled(half, 0);
    for (final s in stations) {
      var axial = s.strike % 180.0;
      if (axial < 0) axial += 180.0;
      var bi = (axial / w).floor();
      if (bi >= half) bi = half - 1;
      core[bi]++;
    }
    return core;
  }

  /// Toliq aylanadagi sektor ro‘yxati (painter bilan mos: har bir
  /// `i` va `i + half` bir xil qiymat).
  static List<int> fullRingCounts(List<int> core, int binCount) {
    final half = binCount ~/ 2;
    if (core.length != half) {
      throw ArgumentError('core uzunligi $half bo‘lishi kerak, ${core.length}');
    }
    return List<int>.generate(binCount, (i) => core[i % half]);
  }
}
