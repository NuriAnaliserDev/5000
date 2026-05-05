import 'dart:convert';

class AiParser {
  static Map<String, dynamic> parseAndValidate(String rawText) {
    String cleaned = _cleanMarkdown(rawText);
    Map<String, dynamic> decoded;
    
    try {
      decoded = jsonDecode(cleaned);
    } catch (e) {
      throw const FormatException("Invalid JSON format from AI.");
    }

    _validateSchema(decoded);
    return decoded;
  }

  static String _cleanMarkdown(String text) {
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

  static void _validateSchema(Map<String, dynamic> json) {
    const requiredKeys = [
      'rockType', 'mineralogy', 'texture', 'structure', 
      'color', 'munsellApprox', 'confidence', 'notes'
    ];
    for (final key in requiredKeys) {
      if (!json.containsKey(key)) {
        throw FormatException("Missing required JSON key: '$key'");
      }
    }
  }
}
