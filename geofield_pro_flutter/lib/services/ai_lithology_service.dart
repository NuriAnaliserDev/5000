import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

import 'ai/ai_rate_limiter.dart';
import '../models/ai_analysis_result.dart';
import '../utils/image_mime.dart';
import '../core/network/network_executor.dart';
import '../core/error/app_error.dart';
import 'hive_db.dart';
import 'ai/image_quality_service.dart';

class AiLithologyService {
  static final AiLithologyService _instance = AiLithologyService._internal();

  factory AiLithologyService() {
    return _instance;
  }

  AiLithologyService._internal();

  /// Analyzes a rock sample from an image using Vertex AI with caching and rate limiting.
  Future<AIAnalysisResult> analyzeRockSample(File imageFile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    
    // 1. Image Hash (sha256)
    final imageBytes = await imageFile.readAsBytes();
    final hash = sha256.convert(imageBytes).toString();

    // 2. Cache Check
    final cacheBox = Hive.box<AIAnalysisResult>(HiveDb.aiCacheBox);
    if (cacheBox.containsKey(hash)) {
      debugPrint('AI: Cache hit for image $hash');
      return cacheBox.get(hash)!;
    }

    // 3. Image Quality Check
    final qualityService = ImageQualityService();
    final qualityResult = await qualityService.analyzeQuality(imageFile);
    if (!qualityResult.isValid) {
      throw AppError(
        "Rasm sifatsiz (xira yoki qorong‘i). Iltimos qayta oling.", 
        category: ErrorCategory.validation
      );
    }

    // 4. Rate Limiting (10s interval + Daily Quota)
    await AiRateLimiter.consume(uid);

    try {
      final model = FirebaseAI.vertexAI().generativeModel(
        model: 'gemini-2.0-flash', // Updated to latest stable flash model
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          temperature: 0.1, 
        ),
      );

      final mime = mimeTypeForImagePath(imageFile.path);

      final prompt = '''
You are a professional field geologist with 20+ years of experience.
Return ONLY valid JSON. No explanations. No Markdown blocks.

Analyze the visual characteristics of the rock in the image and provide a detailed lithological description.
If the image is not a rock or is too blurry, set confidence to 0 and rockType to "Unknown".

Return exactly this JSON schema:
{
  "rockType": "The primary rock type in Uzbek (e.g., Granit, Ohaktosh)",
  "mineralogy": ["Visible minerals in Uzbek (e.g., kvars, biotit)"],
  "texture": "Texture description in Uzbek",
  "structure": "Structure description in Uzbek",
  "color": "Dominant color in Uzbek",
  "munsellApprox": "Munsell Color Code (e.g., 5YR 6/4)",
  "confidence": number between 0 and 1,
  "notes": "Any uncertainty or additional geological context in Uzbek"
}

If confidence < 0.6, explicitly explain why in the notes.
''';

      final content = [
        Content.multi([
          TextPart(prompt),
          InlineDataPart(mime, imageBytes),
        ]),
      ];

      final response = await NetworkExecutor.execute(
        () => model.generateContent(content),
        actionName: 'AI Analyze Lithology',
        maxRetries: 1,
        timeout: const Duration(seconds: 45),
      );

      final respText = response.text;
      if (respText == null || respText.isEmpty) {
        throw AppError("Vertex AI returned an empty response.", category: ErrorCategory.network);
      }

      // 5. Clean and Parse JSON
      final cleanedJson = _cleanJson(respText);
      final decoded = jsonDecode(cleanedJson);

      // 6. Strict Validation
      _validateJson(decoded);

      final result = AIAnalysisResult.fromMap({
        ...decoded,
        'analyzedAt': DateTime.now().toIso8601String(),
      });

      // 7. Save to Cache
      await cacheBox.put(hash, result);
      
      return result;
    } on QuotaExceededException {
      rethrow;
    } on RateLimitException {
      rethrow;
    } catch (e) {
      debugPrint('AI Error: $e');
      if (e is AppError) rethrow;
      throw AppError("AI tahlili bajarilmadi: $e", category: ErrorCategory.unknown);
    }
  }

  String _cleanJson(String text) {
    String cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) {
        cleaned = cleaned.substring(0, cleaned.length - 3);
      }
    }
    return cleaned.trim();
  }

  void _validateJson(Map<String, dynamic> json) {
    final requiredKeys = [
      'rockType', 'mineralogy', 'texture', 'structure', 
      'color', 'munsellApprox', 'confidence', 'notes'
    ];
    for (final key in requiredKeys) {
      if (!json.containsKey(key)) {
        throw Exception("Invalid AI response: Missing key '$key'");
      }
    }
  }
}
