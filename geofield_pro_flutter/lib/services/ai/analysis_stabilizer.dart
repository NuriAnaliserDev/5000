import '../../models/ai_analysis_result.dart';

class AnalysisSession {
  final List<AIAnalysisResult> history = [];

  void add(AIAnalysisResult result) {
    // Strict sliding window to prevent memory leaks in AR mode
    if (history.length >= 10) history.removeAt(0);
    history.add(result);
  }

  void clear() => history.clear();
}

class ResultStabilizer {
  static AIAnalysisResult stabilize(List<AIAnalysisResult> recent) {
    if (recent.isEmpty) throw Exception("Stabilizer needs at least one result");
    if (recent.length == 1) return recent.last;

    // 1. Confidence-Weighted Voting with Time Decay
    // This prevents "Wrong but Stable" scenarios by giving more weight
    // to high-trust results and more recent frames.
    final rockScores = <String, double>{};
    for (int i = 0; i < recent.length; i++) {
      final r = recent[i];
      // Time Decay factor (recent = 1.0, oldest = 0.5)
      final timeWeight = 0.5 + (0.5 * (i + 1) / recent.length);
      // Final vote strength = Trust Score * Time Weight
      final voteStrength = r.trustScore * timeWeight;

      rockCounts(r.rockType, voteStrength, rockScores);
    }

    final dominantRock =
        rockScores.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    // 2. Average Trust Score Smoothing
    final avgTrust =
        recent.map((r) => r.trustScore).reduce((a, b) => a + b) / recent.length;

    // 3. Merge Diagnostics
    final allWarnings = recent
        .expand((r) => r.warningMessage.split(' | '))
        .where((w) => w.trim().isNotEmpty)
        .toSet()
        .toList();

    final allReasons = recent.expand((r) => r.trustReasons).toSet().toList();

    // 4. Final Result Construction
    final latest = recent.last;

    String relLevel = 'high';
    if (avgTrust < 0.3) {
      relLevel = 'reject';
    } else if (avgTrust < 0.6)
      relLevel = 'low';
    else if (avgTrust < 0.85) relLevel = 'medium';

    String status = 'valid';
    if (avgTrust < 0.3) {
      status = 'invalid';
    } else if (avgTrust < 0.7 || allWarnings.isNotEmpty) status = 'suspicious';

    // UI Indicator: Stabilized if we have enough consistent data
    final bool isStabilized =
        recent.length >= 3 && rockScores[dominantRock]! > 1.0;

    return AIAnalysisResult(
      rockType: dominantRock,
      rockCandidates: latest.rockCandidates,
      mineralogy: latest.mineralogy,
      texture: latest.texture,
      structure: latest.structure,
      color: latest.color,
      munsellApprox: latest.munsellApprox,
      confidence: latest.confidence,
      trustScore: avgTrust,
      reliabilityLevel: relLevel,
      trustReasons: allReasons,
      trustBreakdown: latest.trustBreakdown,
      cacheVersion: latest.cacheVersion,
      notes: latest.notes,
      analyzedAt: latest.analyzedAt,
      status: status,
      warningMessage: allWarnings.join(' | '),
      isStabilized: isStabilized,
    );
  }

  static void rockCounts(
      String rock, double strength, Map<String, double> scores) {
    scores[rock] = (scores[rock] ?? 0.0) + strength;
  }
}
