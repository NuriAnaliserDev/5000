import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageQualityResult {
  final bool isBlurry;
  final bool isTooDark;
  final bool isTooBright;
  final double brightnessScore; 
  final double blurVariance;
  final double overallQualityScore; 
  final bool isValid;
  final String errorMessage;

  ImageQualityResult({
    required this.isBlurry,
    required this.isTooDark,
    required this.isTooBright,
    required this.brightnessScore,
    required this.blurVariance,
    required this.overallQualityScore,
    required this.isValid,
    required this.errorMessage,
  });
}

class ImageQualityService {
  // Production-tuned thresholds
  static const double blurThreshold = 60.0; 
  static const double minBrightness = 0.15; 
  static const double maxBrightness = 0.85; 

  Future<ImageQualityResult> analyzeQuality(File file) async {
    final bytes = await file.readAsBytes();
    // Run CPU-heavy processing in a background isolate
    return await compute(_processImage, bytes);
  }

  static ImageQualityResult _processImage(List<int> bytes) {
    final originalImage = img.decodeImage(Uint8List.fromList(bytes));
    if (originalImage == null) {
      return _invalidResult("Rasmni o'qib bo'lmadi.");
    }

    // Resize for faster processing with linear interpolation to preserve edges
    final image = img.copyResize(originalImage, width: 256, interpolation: img.Interpolation.linear);

    double brightnessScore = _calculateBrightness(image);
    double blurVariance = _calculateLaplacianVariance(image);
    
    // Hard rules for immediate rejection
    bool isBlurry = blurVariance < 20.0; // Critical blur
    bool isTooDark = brightnessScore < 0.10; // Critical dark
    bool isTooBright = brightnessScore > 0.95; // Critical bright

    String errorMessage = "";
    if (isTooDark) {
      errorMessage = "Rasm juda qorong'i. Iltimos, yorug'roq joyda qayta oling.";
    } else if (isTooBright) {
      errorMessage = "Rasm o'ta yorug' yoki chaqnagan. Qayta oling.";
    } else if (isBlurry) {
      errorMessage = "Rasm xira (fokus yo'q). Kamerani qimirlatmasdan oling.";
    }

    bool isValid = !isBlurry && !isTooDark && !isTooBright;

    // Weighted Score (Blur is more critical)
    double normBlur = min(blurVariance / (blurThreshold * 2), 1.0);
    double normBright = 1.0 - (0.5 - brightnessScore).abs() * 2; // Closer to 0.5 is ideal
    double overallScore = (normBlur * 0.6) + (normBright * 0.4);

    return ImageQualityResult(
      isBlurry: isBlurry,
      isTooDark: isTooDark,
      isTooBright: isTooBright,
      brightnessScore: brightnessScore,
      blurVariance: blurVariance,
      overallQualityScore: isValid ? max(0.0, overallScore) : 0.0,
      isValid: isValid,
      errorMessage: errorMessage,
    );
  }

  static ImageQualityResult _invalidResult(String msg) {
    return ImageQualityResult(
      isBlurry: false, isTooDark: false, isTooBright: false,
      brightnessScore: 0, blurVariance: 0, overallQualityScore: 0, 
      isValid: false, errorMessage: msg,
    );
  }

  static double _calculateBrightness(img.Image image) {
    double totalLuminance = 0;
    int pixelCount = image.width * image.height;

    for (var p in image) {
      double luminance = 0.299 * p.r + 0.587 * p.g + 0.114 * p.b;
      totalLuminance += luminance;
    }

    double avgLuminance = totalLuminance / pixelCount;
    return avgLuminance / 255.0; 
  }

  static double _calculateLaplacianVariance(img.Image image) {
    // Convert to grayscale
    final gray = img.grayscale(image);
    final width = gray.width;
    final height = gray.height;
    
    List<double> laplacianValues = [];
    double sum = 0;

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        // Grayscale image has same R, G, B values
        double top = gray.getPixel(x, y - 1).r.toDouble();
        double bottom = gray.getPixel(x, y + 1).r.toDouble();
        double left = gray.getPixel(x - 1, y).r.toDouble();
        double right = gray.getPixel(x + 1, y).r.toDouble();
        double center = gray.getPixel(x, y).r.toDouble();

        double laplacian = top + bottom + left + right - (4 * center);
        laplacianValues.add(laplacian);
        sum += laplacian;
      }
    }

    // Release memory early (helps GC)
    gray.clear();

    if (laplacianValues.isEmpty) return 0;

    double mean = sum / laplacianValues.length;
    double varianceSum = 0;

    for (var val in laplacianValues) {
      varianceSum += pow(val - mean, 2);
    }

    return varianceSum / laplacianValues.length;
  }
}
