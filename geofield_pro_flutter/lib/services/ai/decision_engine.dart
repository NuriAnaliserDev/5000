import 'package:flutter/material.dart';
import '../../models/ai_analysis_result.dart';
import '../../models/user_context.dart';

class UXDecision {
  final AppDecision action;
  final String userMessage;
  final Color color;
  final List<String> fallbackActions;

  UXDecision({
    required this.action,
    required this.userMessage,
    required this.color,
    required this.fallbackActions,
  });
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

  static UXDecision decide(AIAnalysisResult result, UserContext context) {
    final level = parseLevel(result.reliabilityLevel);
    
    // Context-Aware Overrides
    ReliabilityLevel effectiveLevel = level;
    
    if (context.role == UserRole.senior || context.role == UserRole.expert) {
      // Seniors can tolerate 'low' AI reliability by manually reviewing (medium warning)
      if (level == ReliabilityLevel.low) {
        effectiveLevel = ReliabilityLevel.medium;
      }
    }
    
    if (context.mode == AppMode.reporting) {
      // Reporting mode is extremely strict; 'medium' becomes 'low' (requires confirmation)
      if (level == ReliabilityLevel.medium) {
        effectiveLevel = ReliabilityLevel.low;
      }
    }

    // UX Mapping & Fallback Strategy
    switch (effectiveLevel) {
      case ReliabilityLevel.high:
        return UXDecision(
          action: AppDecision.autoAccept,
          userMessage: "Ishonch bilan foydalanish mumkin. Geologik mantiq va sifat yuqori.",
          color: Colors.green,
          fallbackActions: ["Tasdiqlash", "Tahrirlash"],
        );
        
      case ReliabilityLevel.medium:
        return UXDecision(
          action: AppDecision.showWithWarning,
          userMessage: "Natijada ba'zi shubhali qismlar mavjud. Tekshirib ko'ring.",
          color: Colors.orange,
          fallbackActions: ["Qayta rasm olish", "Qo'lda to'g'rilash", "Shunday qabul qilish"],
        );
        
      case ReliabilityLevel.low:
        return UXDecision(
          action: AppDecision.requireUserConfirmation,
          userMessage: "Tizim ishonchliligi past. Ehtiyot bo'ling va qayta tekshiring.",
          color: Colors.deepOrange,
          fallbackActions: ["Yaxshiroq rasm olish", "O'lchovni bekor qilish", "Qo'lda kiritish"],
        );
        
      case ReliabilityLevel.reject:
      default:
        // System blocks acceptance. User MUST use fallbacks.
        return UXDecision(
          action: AppDecision.block,
          userMessage: "Natija ishonchsiz. Qabul qilinmaydi.",
          color: Colors.red,
          fallbackActions: ["Kamerani tozalab qayta olish", "Eski ma'lumotdan nusxa olish", "Manual kiritish"],
        );
    }
  }
}
