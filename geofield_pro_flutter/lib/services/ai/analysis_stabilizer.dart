import '../../models/ai_analysis_result.dart';

class AnalysisSession {
  final List<AIAnalysisResult> history = [];
  
  void add(AIAnalysisResult result) {
    if (history.length >= 5) history.removeAt(0); // Keep window small for responsiveness
    history.add(result);
  }

  void clear() => history.clear();
}

class ResultStabilizer {
  static AIAnalysisResult stabilize(List<AIAnalysisResult> recent) {
    if (recent.isEmpty) throw Exception("Stabilizer needs at least one result");
    if (recent.length == 1) return recent.last;

    // 1. RockType Voting (Dominant Type)
    final rockCounts = <String, int>{};
    for (var r in recent) {
      rockCounts[r.rockType] = (rockCounts[r.rockType] ?? 0) + 1;
    }
    final dominantRock = rockCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    // 2. Average Trust Score Smoothing
    final avgTrust = recent.map((r) => r.trustScore).reduce((a, b) => a + b) / recent.length;

    // 3. Merge Diagnostics (Unique Warnings & Reasons)
    final allWarnings = recent
        .expand((r) => r.warningMessage.split(' | '))
        .where((w) => w.trim().isNotEmpty)
        .toSet()
        .toList();
    
    final allReasons = recent.expand((r) => r.trustReasons).toSet().toList();

    // 4. Final Result (Preserve latest attributes but use stabilized metrics)
    final latest = recent.last;
    
    String relLevel = 'high';
    if (avgTrust < 0.3) relLevel = 'reject';
    else if (avgTrust < 0.6) relLevel = 'low';
    else if (avgTrust < 0.85) relLevel = 'medium';

    String status = 'valid';
    if (avgTrust < 0.3) status = 'invalid';
    else if (avgTrust < 0.7 || allWarnings.isNotEmpty) status = 'suspicious';

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
    );
  }
}
