import '../../models/ai_analysis_result.dart';
import 'lithology_validator.dart';

class TrustScore {
  final double finalScore;
  final bool isReliable;
  final List<String> reasons;
  TrustScore(this.finalScore, this.isReliable, this.reasons);
}

class LithologyNormalizer {
  static AIAnalysisResult normalize({
    required Map<String, dynamic> parsedJson,
    required double imageQualityScore,
  }) {
    // 1. Basic Parse
    String rawRockType = (parsedJson['rockType'] ?? 'Unknown').toString().trim();
    List<String> rawMinerals = List<String>.from(parsedJson['mineralogy'] ?? []);
    
    double aiConfidence = (parsedJson['confidence'] ?? 0.0).toDouble();
    List<String> normalizerWarnings = [];

    if (aiConfidence > 1.0 || aiConfidence < 0.0) {
      normalizerWarnings.add("AI kutilmagan confidence qaytardi (\$aiConfidence). Qayta hisoblandi.");
      aiConfidence = aiConfidence.clamp(0.0, 1.0);
    }

    // 2. String Cleanup & Dictionary Parsing (Ambiguity Handling)
    String cleanedRockString = _cleanupRockType(rawRockType);
    List<RockType> parsedRockCandidates = _parseRockCandidates(cleanedRockString);
    List<Mineral> parsedMinerals = _parseMinerals(rawMinerals);

    // 3. Domain Validation (Delegated to Rule Engine with Context)
    final context = ValidationContext(parsedRockCandidates, parsedMinerals);
    final validation = LithologyValidator.validate(context);

    // 4. Trust Engine (System Decision Maker)
    final allWarnings = [...validation.warnings, ...normalizerWarnings];
    double finalScore = (aiConfidence * 0.4) + (validation.domainScore * 0.4) + (imageQualityScore * 0.2);
    
    bool isReliable = true;
    List<String> trustReasons = [];

    if (validation.status == ValidationStatus.invalid) {
      isReliable = false;
      trustReasons.add("SYSTEM: Geologik qoidalar buzilgani sababli natija rad etildi.");
    }
    if (finalScore < 0.5) {
      isReliable = false;
      trustReasons.add("SYSTEM: Umumiy ishonchlilik darajasi (\${(finalScore*100).toStringAsFixed(1)}%) yetarli emas.");
    }
    if (parsedRockCandidates.length > 1) {
      trustReasons.add("SYSTEM: AI bir nechta tosh turlarini taxmin qildi (Noaniqlik aniqlandi).");
      finalScore *= 0.9; // Penalty for ambiguity
    }

    if (isReliable) {
      trustReasons.add("SYSTEM: Tahlil geologik mantiq va sifat tekshiruvlaridan muvaffaqiyatli o'tdi.");
    }

    String status = _determineStatus(validation.status, finalScore, allWarnings);

    return AIAnalysisResult(
      rockType: cleanedRockString,
      rockCandidates: parsedRockCandidates.map((r) => r.name).toList(),
      mineralogy: parsedMinerals.map((m) => m.rawName).toList(),
      texture: parsedJson['texture']?.toString() ?? '',
      structure: parsedJson['structure']?.toString() ?? '',
      color: parsedJson['color']?.toString() ?? '',
      munsellApprox: parsedJson['munsellApprox']?.toString() ?? '',
      confidence: aiConfidence, // Original AI confidence
      trustScore: finalScore.clamp(0.0, 1.0),
      isReliable: isReliable,
      trustReasons: trustReasons,
      aiModelVersion: 1, // Represents Gemini 2.0 Flash initial integration
      notes: parsedJson['notes']?.toString() ?? '',
      analyzedAt: DateTime.now(),
      status: status,
      warningMessage: allWarnings.isNotEmpty ? allWarnings.join(" | ") : '',
    );
  }

  static String _determineStatus(ValidationStatus valStatus, double finalScore, List<String> warnings) {
    if (valStatus == ValidationStatus.invalid || finalScore < 0.4) {
      return 'invalid';
    } else if (valStatus == ValidationStatus.suspicious || finalScore < 0.7 || warnings.isNotEmpty) {
      return 'suspicious';
    }
    return 'valid';
  }

  static String _cleanupRockType(String type) {
    if (type.toLowerCase() == 'unknown') return 'Unknown';
    String t = type.replaceAll(RegExp(r'rock', caseSensitive: false), '')
                   .replaceAll(RegExp(r' toshi', caseSensitive: false), '')
                   .trim();
    if (t.isEmpty) return 'Unknown';
    return t[0].toUpperCase() + t.substring(1);
  }

  static List<RockType> _parseRockCandidates(String input) {
    final lower = input.toLowerCase();
    List<RockType> candidates = [];
    
    if (lower.contains('granit')) candidates.add(RockType.granite);
    if (lower.contains('bazalt') || lower.contains('basalt')) candidates.add(RockType.basalt);
    if (lower.contains('ohak') || lower.contains('limestone')) candidates.add(RockType.limestone);
    if (lower.contains('qum') || lower.contains('sandstone')) candidates.add(RockType.sandstone);
    if (lower.contains('slanets') || lower.contains('shale')) candidates.add(RockType.shale);
    
    if (candidates.isEmpty) candidates.add(RockType.unknown);
    return candidates;
  }

  static List<Mineral> _parseMinerals(List<String> rawMinerals) {
    const goldAliases = ['gold', 'oltin', 'au', 'aurum'];
    const quartzAliases = ['quartz', 'kvars', 'qwartz', 'sio2'];

    return rawMinerals.map((m) {
      final lower = m.toLowerCase();
      String norm = m.trim();
      
      if (goldAliases.any((a) => lower.contains(a))) norm = 'Gold';
      else if (quartzAliases.any((a) => lower.contains(a))) norm = 'Quartz';

      final percentMatch = RegExp(r'(\d+)\s*(?:%|percent|foiz)').firstMatch(lower);
      double? pct;
      if (percentMatch != null) {
        pct = double.tryParse(percentMatch.group(1) ?? '');
      }

      return Mineral(m.trim(), norm, pct);
    }).where((m) => m.rawName.isNotEmpty && m.rawName.toLowerCase() != "noma'lum" && m.rawName.toLowerCase() != 'unknown').toList();
  }
}
