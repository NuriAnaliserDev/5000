import '../../models/ai_analysis_result.dart';

enum ReliabilityLevel {
  high,
  medium,
  low,
  reject
}

enum AppDecision {
  autoAccept,
  showWithWarning,
  requireUserConfirmation,
  block
}

class DecisionEngine {
  static ReliabilityLevel parseLevel(String level) {
    switch (level) {
      case 'high': return ReliabilityLevel.high;
      case 'medium': return ReliabilityLevel.medium;
      case 'reject': return ReliabilityLevel.reject;
      case 'low':
      default:
        return ReliabilityLevel.low;
    }
  }

  static AppDecision decide(AIAnalysisResult result) {
    final level = parseLevel(result.reliabilityLevel);
    
    if (level == ReliabilityLevel.high) {
      return AppDecision.autoAccept;
    }
    
    if (level == ReliabilityLevel.medium) {
      return AppDecision.showWithWarning;
    }
    
    if (level == ReliabilityLevel.low) {
      return AppDecision.requireUserConfirmation;
    }
    
    return AppDecision.block;
  }
}
