class ValidationResult {
  final double domainScore;
  final List<String> warnings;

  ValidationResult(this.domainScore, this.warnings);
}

class LithologyValidator {
  static ValidationResult validateDomainRules(String rockType, List<String> minerals) {
    double domainScore = 1.0;
    List<String> warnings = [];

    // Rule A: Granite / Gold hallucination
    bool hasGold = minerals.any((m) => m.toLowerCase().contains('oltin') || m.toLowerCase().contains('gold'));
    if (rockType.toLowerCase().contains('granit') && hasGold) {
      domainScore -= 0.8;
      warnings.add("Granit tarkibida Oltin aniqlanishi geologik shubhali.");
    }

    // Rule B: Missing minerals for crystalline rocks
    if ((rockType.toLowerCase().contains('granit') || rockType.toLowerCase().contains('bazalt')) 
        && minerals.isEmpty) {
      domainScore -= 0.5;
      warnings.add("Kristallik jins uchun minerallar ko'rsatilmagan.");
    }

    // Rule C: Unknown rock
    if (rockType.toLowerCase() == 'unknown' || rockType.isEmpty) {
      domainScore = 0.0;
      warnings.add("Jins turi aniqlanmadi.");
    }
    
    // Rule D: Out of bound percentages
    for (var m in minerals) {
      final match = RegExp(r'(\d+)%').firstMatch(m);
      if (match != null) {
        int percent = int.tryParse(match.group(1) ?? '0') ?? 0;
        if (percent > 100) {
          domainScore -= 0.4;
          warnings.add("Mineral foizi 100% dan yuqori bo'lishi mumkin emas: $m");
        }
      }
    }

    return ValidationResult(domainScore, warnings);
  }
}
