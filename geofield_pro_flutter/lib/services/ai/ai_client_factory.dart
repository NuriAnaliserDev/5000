import 'package:flutter/foundation.dart';

import '../../core/config/app_features.dart';
import 'ai_client_interface.dart';
import 'gemini_ai_client.dart';
import 'mock_ai_client.dart';
import 'ai_config.dart';

class AiClientFactory {
  static AiClient create() {
    if (!AppFeatures.enableAI || AiConfig.useMock) {
      debugPrint('${AiConfig.modeLog} Initialized (freeze: mock path)');
      return MockAiClient();
    } else {
      debugPrint('${AiConfig.modeLog} Initialized');
      return GeminiAiClient();
    }
  }
}
