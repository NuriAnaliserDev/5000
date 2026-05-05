enum ValidationStatus { valid, suspicious, invalid }

enum RockType { granite, basalt, limestone, sandstone, shale, diorite, gabbro, marble, unknown }

class Mineral {
  final String rawName;
  final String normalizedName;
  final double? percentage;
  
  Mineral(this.rawName, this.normalizedName, this.percentage);
}

class ValidationResult {
  final double domainScore;
  final List<String> warnings;
  final ValidationStatus status;
  
  ValidationResult(this.domainScore, this.warnings, this.status);
}

class ValidationContext {
  final List<RockType> rockCandidates;
  final List<Mineral> minerals;

  ValidationContext(this.rockCandidates, this.minerals);

  bool hasRock(RockType type) => rockCandidates.contains(type);
}

abstract class ValidationRule {
  ValidationRuleResult apply(ValidationContext context);
}

class ValidationRuleResult {
  final double scoreMultiplier;
  final String? warning;
  final bool isCritical;
  
  ValidationRuleResult({
    this.scoreMultiplier = 1.0, 
    this.warning, 
    this.isCritical = false
  });
}

// ==========================================
// GEOLOGICAL RULES ENGINE
// ==========================================

class GraniteGoldRule extends ValidationRule {
  @override
  ValidationRuleResult apply(ValidationContext context) {
    if (context.hasRock(RockType.granite) && context.minerals.any((m) => m.normalizedName == 'Gold')) {
      return ValidationRuleResult(
        scoreMultiplier: 0.3, // Multiplicative penalty
        warning: "Granit tarkibida Oltin aniqlanishi geologik xato.",
      );
    }
    return ValidationRuleResult();
  }
}

class MissingMineralsRule extends ValidationRule {
  @override
  ValidationRuleResult apply(ValidationContext context) {
    if ((context.hasRock(RockType.granite) || context.hasRock(RockType.basalt)) && context.minerals.isEmpty) {
      return ValidationRuleResult(
        scoreMultiplier: 0.6,
        warning: "Kristallik jins uchun minerallar ko'rsatilmagan.",
      );
    }
    return ValidationRuleResult();
  }
}

class PercentageBoundRule extends ValidationRule {
  @override
  ValidationRuleResult apply(ValidationContext context) {
    for (var m in context.minerals) {
      if (m.percentage != null && m.percentage! > 100) {
        return ValidationRuleResult(
          scoreMultiplier: 0.5,
          warning: "Mineral foizi 100% dan oshmasligi kerak: ${m.rawName}",
          isCritical: true, // Forces immediate invalid status
        );
      }
    }
    return ValidationRuleResult();
  }
}

// ==========================================
// VALIDATOR (RULE EXECUTOR)
// ==========================================

class LithologyValidator {
  static final List<ValidationRule> _rules = [
    GraniteGoldRule(),
    MissingMineralsRule(),
    PercentageBoundRule(),
  ];

  static ValidationResult validate(ValidationContext context) {
    double domainScore = 1.0;
    List<String> warnings = [];
    bool hasCritical = false;

    // Apply multiplicative rule engine without side-effects
    for (var rule in _rules) {
      final res = rule.apply(context);
      domainScore *= res.scoreMultiplier;
      if (res.warning != null) warnings.add(res.warning!);
      if (res.isCritical) hasCritical = true;
    }

    domainScore = domainScore.clamp(0.0, 1.0);

    // Context-aware status determination
    ValidationStatus status = ValidationStatus.valid;
    if (hasCritical || domainScore < 0.4) {
      status = ValidationStatus.invalid;
    } else if (domainScore < 0.8 || warnings.length >= 2) {
      status = ValidationStatus.suspicious;
    }

    return ValidationResult(domainScore, warnings, status);
  }
}
