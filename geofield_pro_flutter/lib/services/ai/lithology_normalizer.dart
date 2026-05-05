import '../../models/ai_analysis_result.dart';
import 'lithology_validator.dart';

class LithologyNormalizer {
  // Hash combining versions to reliably invalidate cache
  static const String currentCacheVersion = "ai_v1_norm_v2_val_v3";

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
      aiConfidence = aiConfidence.clamp(0.0, 1.0);
    }

    // 2. String Cleanup & Dictionary Parsing (Ambiguity Handling)
    String cleanedRockString = _cleanupRockType(rawRockType);
    List<RockType> parsedRockCandidates = _parseRockCandidates(cleanedRockString);
    List<Mineral> parsedMinerals = _parseMinerals(rawMinerals);

    // 3. Domain Validation (Delegated to Rule Engine with Context)
    final context = ValidationContext(parsedRockCandidates, parsedMinerals);
    final validation = LithologyValidator.validate(context);

    // 4. Trust Engine (Dynamic Weighting System)
    double aiWeight = 0.4;
    double domainWeight = 0.4;
    double imgWeight = 0.2;

    if (imageQualityScore < 0.4) {
      aiWeight = 0.2;
      domainWeight = 0.3;
      imgWeight = 0.5; 
    } else if (validation.status == ValidationStatus.invalid) {
      domainWeight = 0.7;
      aiWeight = 0.2;
      imgWeight = 0.1;
    }

    double aiContrib = aiConfidence * aiWeight;
    double domainContrib = validation.domainScore * domainWeight;
    double imgContrib = imageQualityScore * imgWeight;
    
    double finalScore = aiContrib + domainContrib + imgContrib;
    
    Map<String, double> trustBreakdown = {
      'ai': aiContrib,
      'domain': domainContrib,
      'image': imgContrib,
    };
    
    List<String> trustReasons = [];

    // Ambiguity Penalty
    if (parsedRockCandidates.length > 1) {
      trustReasons.add("Natijada bir nechta tosh turlari ko'rsatilgan (noaniqlik).");
      finalScore *= 1 - (parsedRockCandidates.length * 0.1); 
    }

    if (imageQualityScore < 0.5) {
      trustReasons.add("Rasm sifati pastligi tahlilga salbiy ta'sir ko'rsatdi.");
    }

    // Reliability Mapping
    String relLevel = 'high';
    if (validation.status == ValidationStatus.invalid || finalScore < 0.3) {
      relLevel = 'reject';
      trustReasons.add("Geologik mantiqqa to'g'ri kelmaydi yoki ishonchlilik o'ta past.");
    } else if (finalScore < 0.6) {
      relLevel = 'low';
      trustReasons.add("Tizim ishonchliligi past, mutaxassis tekshiruvi talab etiladi.");
    } else if (finalScore < 0.85 || validation.status == ValidationStatus.suspicious) {
      relLevel = 'medium';
      if (validation.status == ValidationStatus.suspicious) {
        trustReasons.add("Tahlilda ba'zi geologik shubhalar mavjud.");
      }
    }

    if (relLevel == 'high') {
      trustReasons.add("Tahlil geologik mantiq va sifat tekshiruvlaridan muvaffaqiyatli o'tdi.");
    }

    final allWarnings = [...validation.warnings, ...normalizerWarnings];
    String status = _determineStatus(validation.status, finalScore, allWarnings);

    return AIAnalysisResult(
      rockType: cleanedRockString,
      rockCandidates: parsedRockCandidates.map((r) => r.name).toList(),
      mineralogy: parsedMinerals.map((m) => m.rawName).toList(),
      texture: parsedJson['texture']?.toString() ?? '',
      structure: parsedJson['structure']?.toString() ?? '',
      color: parsedJson['color']?.toString() ?? '',
      munsellApprox: parsedJson['munsellApprox']?.toString() ?? '',
      confidence: aiConfidence,
      trustScore: finalScore.clamp(0.0, 1.0),
      reliabilityLevel: relLevel,
      trustReasons: trustReasons,
      trustBreakdown: trustBreakdown,
      cacheVersion: currentCacheVersion,
      notes: parsedJson['notes']?.toString() ?? '',
      analyzedAt: DateTime.now(),
      status: status,
      warningMessage: allWarnings.isNotEmpty ? allWarnings.join(" | ") : '',
    );
  }

  static String _determineStatus(ValidationStatus valStatus, double finalScore, List<String> warnings) {
    if (valStatus == ValidationStatus.invalid || finalScore < 0.3) return 'invalid';
    if (valStatus == ValidationStatus.suspicious || finalScore < 0.7 || warnings.isNotEmpty) return 'suspicious';
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
