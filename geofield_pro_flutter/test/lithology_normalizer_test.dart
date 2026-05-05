import 'package:flutter_test/flutter_test.dart';
import '../lib/services/ai/lithology_normalizer.dart';

void main() {
  group('LithologyNormalizer Tests (Domain Validation & Trust System)', () {
    
    test('Rule A: Invalid Geology (Granite + 80% Gold) -> Suspicious/Invalid', () {
      final rawJson = {
        'rockType': 'Granit',
        'mineralogy': ['Kvars 20%', 'Oltin 80%'],
        'confidence': 0.95,
      };

      final result = LithologyNormalizer.normalize(
        parsedJson: rawJson, 
        imageQualityScore: 0.9
      );

      expect(result.status, isNot('valid')); // Should be suspicious or invalid
      expect(result.warningMessage, contains('Oltin'));
      // Real confidence drops drastically because of hallucination
      expect(result.confidence, lessThan(0.95)); 
    });

    test('Rule B: Crystalline rock without minerals -> Suspicious', () {
      final rawJson = {
        'rockType': 'Bazalt',
        'mineralogy': [],
        'confidence': 0.9,
      };

      final result = LithologyNormalizer.normalize(
        parsedJson: rawJson, 
        imageQualityScore: 0.9
      );

      expect(result.status, isNot('valid'));
      expect(result.warningMessage, contains('Kristallik jins'));
    });

    test('Rule D: Percentage > 100% -> Suspicious', () {
      final rawJson = {
        'rockType': 'Slanets',
        'mineralogy': ['Biotit 150%'],
        'confidence': 0.8,
      };

      final result = LithologyNormalizer.normalize(
        parsedJson: rawJson, 
        imageQualityScore: 0.9
      );

      expect(result.status, isNot('valid'));
      expect(result.warningMessage, contains('100% dan yuqori'));
    });

    test('Normal case -> Valid', () {
      final rawJson = {
        'rockType': 'Ohaktosh',
        'mineralogy': ['Kalsit 90%', 'Dolomit 10%'],
        'confidence': 0.9, // AI confidence
      };

      final result = LithologyNormalizer.normalize(
        parsedJson: rawJson, 
        imageQualityScore: 0.9 // High quality image
      );

      expect(result.status, equals('valid'));
      expect(result.warningMessage, isEmpty);
      // Real confidence = 0.9*0.5 + 0.9*0.3 + 1.0*0.2 = 0.45 + 0.27 + 0.2 = 0.92
      expect(result.confidence, closeTo(0.92, 0.01));
    });

    test('String cleanup ignores noise and formats names', () {
      final rawJson = {
        'rockType': 'granit toshi', // Should become 'Granit'
        'mineralogy': [' kvars ', 'noma\'lum', 'Unknown', 'biotit'], // Should drop unknowns and trim
        'confidence': 0.8,
      };

      final result = LithologyNormalizer.normalize(
        parsedJson: rawJson, 
        imageQualityScore: 0.8
      );

      expect(result.rockType, equals('Granit'));
      expect(result.mineralogy.length, equals(2));
      expect(result.mineralogy.contains('kvars'), isTrue);
      expect(result.mineralogy.contains('biotit'), isTrue);
    });

  });
}
