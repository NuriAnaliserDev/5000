import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:geofield_pro_flutter/services/ai/mock_ai_client.dart';
import 'package:geofield_pro_flutter/services/ai/ai_parser.dart';
import 'package:geofield_pro_flutter/services/ai/lithology_normalizer.dart';
import 'package:geofield_pro_flutter/services/ai/decision_engine.dart';

void main() {
  group('AI Mock System Tests', () {
    final mockClient = MockAiClient();
    final dummyFile = File('dummy.jpg');
    final dummyBytes = Uint8List(0);

    test('Mock mode produces varied and realistic scenarios', () async {
      final results = <String>{};
      
      // Run multiple times to see different scenarios
      for (int i = 0; i < 20; i++) {
        final rawJson = await mockClient.generateContent(dummyFile, dummyBytes);
        final parsed = AiParser.parseAndValidate(rawJson);
        results.add(parsed['rockType']);
      }
      
      // Should at least have Granite and likely something else
      expect(results.contains('Granit'), isTrue);
      expect(results.length, greaterThan(1));
    });

    test('System handles Hallucination (Granite + Gold) correctly in Mock Mode', () async {
       // Manual setup to force the hallucination scenario logic
       final hallucinationJson = {
        "rockType": "Granit",
        "mineralogy": ["Kvars", "Oltin 80%"],
        "texture": "Kristalli",
        "structure": "Massiv",
        "color": "Sariq-yaltiroq",
        "munsellApprox": "2.5Y 8/8",
        "confidence": 0.95,
        "notes": "Toshda juda ko'p oltin zarralari ko'rinmoqda."
      };

      final normalized = LithologyNormalizer.normalize(
        parsedJson: hallucinationJson,
        imageQualityScore: 0.9,
      );

      final ux = DecisionEngine.decide(normalized, UserContext());

      expect(normalized.status, equals('invalid'));
      expect(ux.action, equals(AppDecision.block));
      expect(normalized.trustReasons.any((r) => r.contains('Oltin')), isTrue);
    });

    test('System handles Ambiguity penalty correctly', () async {
       final ambiguousJson = {
        "rockType": "Granit yoki Diorit",
        "mineralogy": ["Kvars"],
        "texture": "Porfirli",
        "structure": "Massiv",
        "color": "Kulrang",
        "munsellApprox": "N 5/",
        "confidence": 0.7,
        "notes": "Ikkita variant bor."
      };

      final normalized = LithologyNormalizer.normalize(
        parsedJson: ambiguousJson,
        imageQualityScore: 0.9,
      );

      // Ambiguity penalty: 1 - (2 * 0.1) = 0.8x multiplier
      // Score: (0.7 * 0.4 + 1.0 * 0.4 + 0.9 * 0.2) * 0.8 = (0.28 + 0.4 + 0.18) * 0.8 = 0.86 * 0.8 = 0.688
      expect(normalized.trustScore, closeTo(0.688, 0.01));
      expect(normalized.reliabilityLevel, equals('low'));
    });
  });
}
