import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import '../lib/services/ai/image_quality_service.dart';

void main() {
  group('ImageQualityService Tests', () {
    late Directory tempDir;
    late ImageQualityService qualityService;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync();
      qualityService = ImageQualityService();
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    File _createTestImage(String name, img.Image image) {
      final file = File('${tempDir.path}/$name.png');
      file.writeAsBytesSync(img.encodePng(image));
      return file;
    }

    test('Dark image -> rejected', () async {
      // Create a 100x100 dark image
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(10, 10, 10)); // Very dark
      final file = _createTestImage('dark', image);

      final result = await qualityService.analyzeQuality(file);
      expect(result.brightnessScore, lessThan(ImageQualityService.minBrightness));
      expect(result.isValid, isFalse);
    });

    test('Blurry image -> rejected', () async {
      // A flat color has 0 variance (perfectly blurry/no edges)
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgb8(128, 128, 128)); // Mid gray
      final file = _createTestImage('blurry', image);

      final result = await qualityService.analyzeQuality(file);
      expect(result.isBlurry, isTrue);
      expect(result.isValid, isFalse);
    });

    test('Normal image -> passes', () async {
      // Create an image with edges (checkerboard pattern)
      final image = img.Image(width: 100, height: 100);
      for (int y = 0; y < 100; y++) {
        for (int x = 0; x < 100; x++) {
          int c = (x ~/ 10 + y ~/ 10) % 2 == 0 ? 200 : 50; // Edges
          image.setPixelRgb(x, y, c, c, c);
        }
      }
      final file = _createTestImage('normal', image);

      final result = await qualityService.analyzeQuality(file);
      expect(result.brightnessScore, greaterThan(ImageQualityService.minBrightness));
      expect(result.brightnessScore, lessThan(ImageQualityService.maxBrightness));
      expect(result.isBlurry, isFalse);
      expect(result.isValid, isTrue);
    });
  });
}
