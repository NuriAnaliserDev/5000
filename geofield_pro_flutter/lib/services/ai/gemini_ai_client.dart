import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_ai/firebase_ai.dart';
import '../../core/network/network_executor.dart';
import '../../core/error/app_error.dart';
import '../../utils/image_mime.dart';
import 'ai_client_interface.dart';

class GeminiAiClient implements AiClient {
  static const String _modelName = 'gemini-2.0-flash';
  static const String _prompt = '''
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

  @override
  Future<String> generateContent(File imageFile, Uint8List imageBytes) async {
    final model = FirebaseAI.vertexAI().generativeModel(
      model: _modelName,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.1, 
      ),
    );

    final mime = mimeTypeForImagePath(imageFile.path);

    final content = [
      Content.multi([
        TextPart(_prompt),
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
    return respText;
  }
}
