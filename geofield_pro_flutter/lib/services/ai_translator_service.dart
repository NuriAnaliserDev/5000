import 'dart:convert';
import 'dart:io';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'ai/ai_rate_limiter.dart';
import '../core/error/app_error.dart';
import '../utils/image_mime.dart';
import '../core/network/network_executor.dart';

class AiTranslatorService {
  late final GenerativeModel _model;

  AiTranslatorService() {
    _model = FirebaseAI.vertexAI().generativeModel(
      model: 'gemini-2.5-flash',
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
  }

  Future<Map<String, dynamic>> analyzeReportImage(String imagePath) async {
    try {
      Uint8List bytes;
      String mime;
      if (imagePath.startsWith('http')) {
        final response = await NetworkExecutor.execute(
          () => http.get(Uri.parse(imagePath)),
          actionName: 'Download Report Image',
          maxRetries: 2,
        );
        if (response.statusCode != 200) {
          throw AppError("Rasmni yuklashda xatolik: ${response.statusCode}",
              category: ErrorCategory.network);
        }
        bytes = response.bodyBytes;
        mime =
            mimeTypeFromContentTypeHeader(response.headers['content-type']) ??
                mimeTypeForImagePath(imagePath);
      } else {
        if (kIsWeb) {
          throw AppError("Web muhitda lokal fayl yo'llari ruxsat etilmagan",
              category: ErrorCategory.validation);
        }
        final file = File(imagePath);
        bytes = await file.readAsBytes();
        mime = mimeTypeForImagePath(imagePath);
      }

      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      await AiRateLimiter.consume(uid);

      final imagePart = InlineDataPart(mime, bytes);

      final prompt = TextPart('''
Siz professional konchilik geologisisiz. Rasmda qolyozma hisobot tasvirlangan.
Maqsad rasmdan ma'lumotlarni ajratib, qat'iy JSON formatida qaytarishdir.

AVVAL HUJJAT TURINI ANIQLANG. Uch tur mavjud:

---
1-TUR: RC BURG'ULASH ("rc_drill")
Belgilari: "RC Hole_ID", "Depth", "Sample No From", "Sample No To", "Downtimes", "Rig ID", "RC Daily Operation Report"
JSON:
{
  "report_type": "rc_drill",
  "rig_id": "RIG",
  "rig_model": "FSL-600",
  "contractor": "MINEX",
  "date": "05.04.26",
  "project": "KNIR",
  "purpose": "GC",
  "shift": "day",
  "holes": [
    {"no": 1, "hole_id": "KNRGC2122", "depth": "15M", "sample_from": "GC0061864", "sample_to": "GC0061878", "sample_count": "15"}
  ],
  "total_depth": "119M",
  "total_samples": "122",
  "downtimes": [
    {"from": "7:00", "to": "10:30", "sub_total": "3:30", "cause": "Qabul qilish", "action": "Ta'mirlash", "remarks": "Golgan 2127 quduqni"}
  ]
}

---
2-TUR: SPOTTER / ORE BLOCK ("ore_block")
Belgilari: "Ore Block Details", "Block #", "Destination", "RL Toe", "Total Loads", "Load Times", "MARG", "SKLAD", krestiklar (+)
JSON:
{
  "report_type": "ore_block",
  "date": "04.04.26",
  "shift": "DS1",
  "spotter": "Nurmamatov",
  "pit": "P1",
  "horizon": "250",
  "markup": "042",
  "block_full": "P1250042 MARG 00648",
  "destination": "MARG SKLAD",
  "rl_toe": "250",
  "excavator": "3",
  "completed": "Y",
  "shot": "0.249/6",
  "total_loads": "34",
  "grade": "0.24 g/t",
  "floor_level_time": "22:50",
  "floor_level_height": "5m"
}

---
3-TUR: ORE STOCKPILE MONITORING ("ore_stockpile")
Belgilari: "ORE STOCKPILE DAILY WORKING MONITORING", "Loader", "Material", soatlik katakchalar, "7-8", "8-9" kabi vaqt ustunlari
JSON:
{
  "report_type": "ore_stockpile",
  "date": "02.04.26",
  "shift": "DAY",
  "geologist": "Yusupov Dilnoz ulug",
  "loaders": [
    {
      "loader_id": "Loader_1 (12-101)",
      "route": "12-301",
      "material": "MG 12",
      "grade": "0.74",
      "total_loads": "86"
    },
    {
      "loader_id": "Loader_2 (12-102)",
      "route": "12-101",
      "material": "MG 12",
      "grade": "0.74",
      "total_loads": "50"
    }
  ],
  "grand_total": "272"
}

---
DIQQAT:
- Natija FAQAT toza JSON formatida bo'lsin (``` belgilarsiz, to'g'ridan-to'g'ri { bilan boshlang)
- Boshqa izoh yozmang
- Qolyozmani diqqat bilan o'qing, raqamlarni to'g'ri ko'chiring
''');

      final response = await NetworkExecutor.execute(
        () => _model.generateContent([
          Content.multi([prompt, imagePart])
        ]),
        actionName: 'AI Translate Image',
        maxRetries: 1,
        timeout: const Duration(seconds: 45), // AI usually takes longer
      );

      final respText = response.text;
      if (respText == null || respText.isEmpty) {
        throw AppError("AI bo'sh natija qaytardi.",
            category: ErrorCategory.network);
      }
      final rawJson = respText
          .trim()
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      return jsonDecode(rawJson) as Map<String, dynamic>;
    } catch (e) {
      // NetworkExecutor xatolikni log qilib beradi
      debugPrint("AI Analyzer Error: $e");
      return {
        "error": e.toString(),
      };
    }
  }
}
