import 'dart:io';
import 'dart:typed_data';

abstract class AiClient {
  /// Analyzes the rock in the image and returns a raw JSON string
  Future<String> generateContent(File imageFile, Uint8List imageBytes);
}
