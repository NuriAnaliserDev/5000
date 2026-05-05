import '../../models/ai_analysis_result.dart';
import 'lithology_validator.dart';

class LithologyNormalizer {
  static AIAnalysisResult normalize({
    required Map<String, dynamic> parsedJson,
    required double imageQualityScore,
  }) {
    // 1. Basic Parse
    String rawRockType = (parsedJson['rockType'] ?? 'Unknown').toString().trim();
    List<String> rawMinerals = List<String>.from(parsedJson['mineralogy'] ?? []);
    double aiConfidence = (parsedJson['confidence'] ?? 0.0).toDouble().clamp(0.0, 1.0);

    // 2. String Cleanup
    String rockType = _cleanupRockType(rawRockType);
    List<String> minerals = _cleanupMinerals(rawMinerals);

    // 3. Domain Validation (Delegated)
    final validation = LithologyValidator.validateDomainRules(rockType, minerals);

    // 4. Real Confidence Calculation (Trust System)
    final realConfidence = (aiConfidence * 0.5) + 
                           (imageQualityScore * 0.3) + 
                           (validation.domainScore * 0.2);

    // 5. Status Determination
    String status = _determineStatus(validation.domainScore, realConfidence, validation.warnings);

    return AIAnalysisResult(
      rockType: rockType,
      mineralogy: minerals,
      texture: parsedJson['texture']?.toString() ?? '',
      structure: parsedJson['structure']?.toString() ?? '',
      color: parsedJson['color']?.toString() ?? '',
      munsellApprox: parsedJson['munsellApprox']?.toString() ?? '',
      confidence: realConfidence.clamp(0.0, 1.0),
      notes: parsedJson['notes']?.toString() ?? '',
      analyzedAt: DateTime.now(),
      status: status,
      warningMessage: validation.warnings.isNotEmpty ? validation.warnings.join(" ") : '',
    );
  }

  static String _determineStatus(double domainScore, double confidence, List<String> warnings) {
    if (domainScore < 0.3 || confidence < 0.4) {
      return 'invalid';
    } else if (domainScore < 0.8 || confidence < 0.7 || warnings.isNotEmpty) {
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

  static List<String> _cleanupMinerals(List<String> minerals) {
    return minerals
        .map((m) => m.trim())
        .where((m) => m.isNotEmpty && m.toLowerCase() != 'noma\'lum' && m.toLowerCase() != 'unknown')
        .toList();
  }
}
