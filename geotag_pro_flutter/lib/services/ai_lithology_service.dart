import 'dart:convert';
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'ai/ai_rate_limiter.dart';

class AiLithologyResponse {
  final String rockType;
  final List<String> minerals;
  final String description;
  final int confidence;
  final String munsellColor;

  AiLithologyResponse({
    required this.rockType,
    required this.minerals,
    required this.description,
    required this.confidence,
    required this.munsellColor,
  });

  factory AiLithologyResponse.fromJson(Map<String, dynamic> json) {
    return AiLithologyResponse(
      rockType: json['rock_type'] ?? 'Noma\'lum',
      minerals: List<String>.from(json['minerals'] ?? []),
      description: json['description'] ?? '',
      confidence: json['confidence'] ?? 3,
      munsellColor: json['munsell_color'] ?? 'N 8',
    );
  }
}

class AiLithologyService {
  static final AiLithologyService _instance = AiLithologyService._internal();

  factory AiLithologyService() {
    return _instance;
  }

  AiLithologyService._internal();

  /// Analyzes a rock sample from an image using Vertex AI.
  ///
  /// Har chaqiruvdan oldin [AiRateLimiter.consume] orqali kundalik kvota
  /// tekshiriladi. Agar kvota oshib ketsa [QuotaExceededException] tashlanadi.
  Future<AiLithologyResponse> analyzeRockSample(File imageFile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    await AiRateLimiter.consume(uid);

    try {
      final model = FirebaseAI.vertexAI().generativeModel(
        model: 'gemini-1.5-flash',
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1, // Low temperature for factual, deterministic analysis
        ),
      );

      final imageBytes = await imageFile.readAsBytes();
      
      final prompt = '''
Sen professional katta (Senior) geologsan. 
Quyidagi rasmni vizual analiz qilib uning litologik tarkibini aniqla va ma'lumotlarni faqat berilgan JSON formatida qaytar.
Hech qanday qo'shimcha matn (Markdown bloklarsiz) ishlatma.
Agar rasmda tosh yoq bolsa yoki noaniq bolsa noma'lum dеb qaytar.

Javob berish formati (JSON):
{
  "rock_type": "Toshning asosiy turi (masalan: Granit, Ohaktosh, Slanets... o'zbek tilida)",
  "minerals": ["Rasmda ko'zga ko'rinadigan asosiy jins hosil qiluvchi minerallar o'zbek tilida (kvars, shpat, biotit..)"],
  "description": "Geologik vizual tekstura va struktura haqida qisqacha tasvirlash (o'zbek tilida)",
  "confidence": 1 dan 5 gacha ishonch darajasi (integer, 5 eng ishonchli),
  "munsell_color": "Munsell Color Code tizimi yordamida toshning asosiy rang kodini taxminiy berish (masalan: 5YR 6/4)"
}
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          InlineDataPart('image/jpeg', imageBytes),
        ]),
      ];

      final response = await model.generateContent(content);
      
      final respText = response.text;
      if (respText == null || respText.isEmpty) {
        throw Exception("Vertex AIDan javob kelmadi.");
      }

      // Ba'zan gemini jsonni markdown blok ichiga olib beradi
      String cleanedJson = respText.trim();
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.substring(7);
        if (cleanedJson.endsWith('```')) {
          cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
        }
      } else if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.substring(3);
        if (cleanedJson.endsWith('```')) {
          cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3);
        }
      }

      final decoded = jsonDecode(cleanedJson.trim());
      return AiLithologyResponse.fromJson(decoded);
    } on QuotaExceededException {
      rethrow;
    } catch (e) {
      debugPrint("AI tahlil xatosi: $e");
      throw Exception("AI tahlilida xatolik: $e");
    }
  }
}
