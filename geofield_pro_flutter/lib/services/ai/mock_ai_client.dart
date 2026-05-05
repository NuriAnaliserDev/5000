import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'ai_client_interface.dart';

enum MockScenario {
  validGranite,
  hallucinationGold,
  ambiguous,
  lowConfidence,
  unknown,
  networkTimeout,
  invalidJson
}

class MockAiClient implements AiClient {
  final _random = Random();
  
  /// If not empty, will play these scenarios in order
  static List<MockScenario> script = [];
  static int _scriptIndex = 0;

  @override
  Future<String> generateContent(File imageFile, Uint8List imageBytes) async {
    // 1. Determine Scenario
    MockScenario scenario;
    if (script.isNotEmpty) {
      scenario = script[_scriptIndex % script.length];
      _scriptIndex++;
    } else {
      final r = _random.nextInt(100);
      if (r < 10) scenario = MockScenario.networkTimeout;
      else if (r < 15) scenario = MockScenario.invalidJson;
      else if (r < 60) scenario = MockScenario.validGranite;
      else if (r < 75) scenario = MockScenario.hallucinationGold;
      else if (r < 85) scenario = MockScenario.ambiguous;
      else if (r < 95) scenario = MockScenario.lowConfidence;
      else scenario = MockScenario.unknown;
    }

    // 2. Simulate Delay
    final delay = 400 + _random.nextInt(600);
    await Future.delayed(Duration(milliseconds: delay));

    // 3. Execute Scenario
    switch (scenario) {
      case MockScenario.networkTimeout:
        throw Exception("Connection timeout (Mock)");
        
      case MockScenario.invalidJson:
        return "Internal Server Error: {invalid_json_here}";

      case MockScenario.validGranite:
        return _json({
          "rockType": "Granit",
          "mineralogy": ["Kvars", "Biotit"],
          "texture": "To'liq kristalli",
          "structure": "Massiv",
          "color": "Kulrang",
          "munsellApprox": "5YR 7/1",
          "confidence": 0.88,
          "notes": "Namuna aniq."
        });

      case MockScenario.hallucinationGold:
        return _json({
          "rockType": "Granit",
          "mineralogy": ["Kvars", "Oltin 90%"],
          "texture": "Yaltiroq",
          "structure": "Massiv",
          "color": "Sariq",
          "munsellApprox": "2.5Y 8/8",
          "confidence": 0.98,
          "notes": "Xazina topildi!"
        });

      case MockScenario.ambiguous:
        return _json({
          "rockType": "Granit yoki Diorit",
          "mineralogy": ["Kvars", "Hornblende"],
          "texture": "Porfirli",
          "structure": "Massiv",
          "color": "To'q kulrang",
          "munsellApprox": "N 4/",
          "confidence": 0.62,
          "notes": "Ikkita ehtimol."
        });

      case MockScenario.lowConfidence:
        return _json({
          "rockType": "Bazalt",
          "mineralogy": [],
          "texture": "Afanitli",
          "structure": "G'ovakli",
          "color": "Qora",
          "munsellApprox": "N 2/",
          "confidence": 0.25,
          "notes": "Juda xira rasm."
        });

      case MockScenario.unknown:
        return _json({
          "rockType": "Noma'lum",
          "mineralogy": [],
          "texture": "Noma'lum",
          "structure": "Noma'lum",
          "color": "Noma'lum",
          "munsellApprox": "N/A",
          "confidence": 0.0,
          "notes": "Tosh emas."
        });
    }
  }

  String _json(Map<String, dynamic> data) => jsonEncode(data);

  /// Helper to set a test script
  static void setScript(List<MockScenario> newScript) {
    script = newScript;
    _scriptIndex = 0;
  }
}
