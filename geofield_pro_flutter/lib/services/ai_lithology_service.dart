import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

import '../models/ai_analysis_result.dart';
import '../core/error/app_error.dart';
import 'hive_db.dart';
import 'ai/ai_rate_limiter.dart';
import 'ai/image_quality_service.dart';
import 'ai/ai_client.dart';
import 'ai/ai_parser.dart';
import 'ai/lithology_normalizer.dart';

class AiLithologyService {
  static final AiLithologyService _instance = AiLithologyService._internal();

  factory AiLithologyService() => _instance;

  AiLithologyService._internal();

  /// Orchestrates the entire AI processing pipeline
  Future<AIAnalysisResult> analyzeRockSample(File imageFile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final imageBytes = await imageFile.readAsBytes();
    final hash = sha256.convert(imageBytes).toString();

    // 1. Cache Check
    final cacheBox = Hive.box<AIAnalysisResult>(HiveDb.aiCacheBox);
    if (cacheBox.containsKey(hash)) {
      debugPrint('AI: Cache hit for image $hash');
      return cacheBox.get(hash)!;
    }

    // 2. Image Quality Gate
    final qualityService = ImageQualityService();
    final qualityResult = await qualityService.analyzeQuality(imageFile);
    if (!qualityResult.isValid) {
      throw AppError(qualityResult.errorMessage, category: ErrorCategory.validation);
    }

    // 3. Rate Limiting Check
    await AiRateLimiter.consume(uid);

    // 4. Processing Loop (with Retry Strategy)
    int maxRetries = 1;
    final client = AiClient();

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final rawText = await client.generateContent(imageFile, imageBytes);
        final parsedJson = AiParser.parseAndValidate(rawText);
        
        final result = LithologyNormalizer.normalize(
          parsedJson: parsedJson,
          imageQualityScore: qualityResult.overallQualityScore,
        );

        if (result.status == 'invalid' && attempt < maxRetries) {
          debugPrint('AI result invalid or hallucinatory, retrying... (\${attempt + 1})');
          continue;
        }

        // 5. Cache & Return Result
        await cacheBox.put(hash, result);
        return result;

      } on QuotaExceededException {
        rethrow;
      } on RateLimitException {
        rethrow;
      } catch (e) {
        if (attempt == maxRetries) {
          debugPrint('AI Error: \$e');
          if (e is AppError) rethrow;
          throw AppError("AI tahlili bajarilmadi: \$e", category: ErrorCategory.unknown);
        }
        debugPrint('AI parsing or network failed, retrying... (\${attempt + 1})');
      }
    }
    
    throw AppError("AI tahlili amalga oshmadi.", category: ErrorCategory.unknown);
  }
}
