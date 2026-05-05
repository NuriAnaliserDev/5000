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
import 'ai/ai_client_interface.dart';
import 'ai/ai_client_factory.dart';
import 'ai/ai_parser.dart';
import 'ai/lithology_normalizer.dart';
import 'ai/decision_engine.dart';
import 'ai/analysis_stabilizer.dart';

class AiLithologyService {
  static final AiLithologyService _instance = AiLithologyService._internal();

  factory AiLithologyService() => _instance;

  AiLithologyService._internal();
  
  final _session = AnalysisSession();
  
  // Simple in-memory metrics (Production would use Analytics service)
  int _totalRequests = 0;
  int _rejects = 0;
  int _ambiguities = 0;
  
  DateTime? _lastAnalysisTime;

  /// Orchestrates the entire AI processing pipeline
  Future<AIAnalysisResult> analyzeRockSample(File imageFile) async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final imageBytes = await imageFile.readAsBytes();
    final hash = sha256.convert(imageBytes).toString();

    // 0. Throttling Gate (AR Readiness)
    final now = DateTime.now();
    if (_lastAnalysisTime != null) {
      final diff = now.difference(_lastAnalysisTime!);
      if (diff.inSeconds < 2 && _session.history.isNotEmpty) {
        debugPrint('AI [THROTTLED]: Returning stabilized session result.');
        return ResultStabilizer.stabilize(_session.history);
      }
    }
    _lastAnalysisTime = now;

    // 1. Cache Check with TTL (7 days) and Versioning
    final cacheBox = Hive.box<AIAnalysisResult>(HiveDb.aiCacheBox);
    if (cacheBox.containsKey(hash)) {
      final cached = cacheBox.get(hash)!;
      final age = DateTime.now().difference(cached.analyzedAt);
      if (age.inDays > 7 || cached.cacheVersion != LithologyNormalizer.currentCacheVersion) {
        debugPrint('AI [CACHE MISS]: TTL expired or Model Version changed for hash $hash.');
        await cacheBox.delete(hash);
      } else {
        debugPrint('AI [CACHE HIT]: Reusing valid result for hash $hash.');
        return cached;
      }
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
    final client = AiClientFactory.create();

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final rawText = await client.generateContent(imageFile, imageBytes);
        debugPrint('AI [RAW RESPONSE]: $rawText');
        final parsedJson = AiParser.parseAndValidate(rawText);
        
        final result = LithologyNormalizer.normalize(
          parsedJson: parsedJson,
          imageQualityScore: qualityResult.overallQualityScore,
        );

        debugPrint('AI [NORMALIZATION]: Status: \${result.status}, Confidence: \${result.confidence}');
        if (result.warningMessage.isNotEmpty) {
          debugPrint('AI [WARNINGS]: \${result.warningMessage}');
        }

        // Domain failure -> DO NOT retry, return immediately so UI handles the hallucination
        if (result.status == 'invalid') {
          debugPrint('AI [DOMAIN ERROR]: Result rejected by validator. Passing to UI without retry.');
        }

        // 5. UX Decision & Metrics
        final uxDecision = DecisionEngine.decide(result, UserContext());
        
        _totalRequests++;
        if (uxDecision.action == AppDecision.block) _rejects++;
        if (result.rockCandidates.length > 1) _ambiguities++;

        debugPrint('AI_METRIC [DECISION]: ${uxDecision.action.name} for hash $hash.');
        debugPrint('AI_STATS [SESSION]: Total: $_totalRequests, Rejects: $_rejects, AmbiguityRate: ${(_ambiguities/(_totalRequests == 0 ? 1 : _totalRequests) * 100).toStringAsFixed(1)}%');

        // 6. Temporal Stabilization
        _session.add(result);
        final stabilized = ResultStabilizer.stabilize(_session.history);

        // 7. Cache & Return Result
        await cacheBox.put(hash, stabilized);
        debugPrint('AI [SUCCESS]: Pipeline completed with stabilization.');
        return stabilized;

      } on QuotaExceededException {
        rethrow;
      } on RateLimitException {
        rethrow;
      } on FormatException catch (e) {
        // Parsing Error -> Retry
        if (attempt < maxRetries) {
          debugPrint('AI [PARSING ERROR]: Invalid JSON structure. Retrying... (\${attempt + 1})');
          continue;
        }
        debugPrint('AI [FATAL PARSING ERROR]: Max retries reached.');
        throw AppError("AI javobi noto'g'ri formatda keldi.", category: ErrorCategory.unknown);
      } catch (e) {
        if (attempt == maxRetries) {
          debugPrint('AI [NETWORK/SYSTEM ERROR]: \$e');
          if (e is AppError) rethrow;
          throw AppError("AI tahlili bajarilmadi: \$e", category: ErrorCategory.unknown);
        }
        debugPrint('AI [UNKNOWN ERROR]: Retrying... (\${attempt + 1})');
      }
    }
    
    throw AppError("AI tahlili amalga oshmadi.", category: ErrorCategory.unknown);
  }
}
