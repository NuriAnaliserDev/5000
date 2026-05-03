import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';

class ImageUtils {
  static Future<XFile> burnScaleBar({
    required String path,
    required double pixelsPerMm,
  }) async {
    try {
      final bytes = await File(path).readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return XFile(path);

      final w = image.width;
      final h = image.height;

      // Calculate scale factor based on standard 1080p screen width reference
      const estimatedScreenPx = 1080.0;
      final scaleFactor = w / estimatedScreenPx;

      final barWidth =
          (pixelsPerMm * 10.0 * scaleFactor).toInt().clamp(20, w ~/ 3);
      final barHeight = (h * 0.012).toInt().clamp(4, 20);
      final margin = (w * 0.03).toInt();

      final x = w - barWidth - margin;
      final y = h - barHeight - margin;

      // Draw white background bar
      img.fillRect(image,
          x1: x,
          y1: y,
          x2: x + barWidth,
          y2: y + barHeight,
          color: img.ColorRgb8(255, 255, 255));

      // Draw black outline
      img.drawRect(image,
          x1: x,
          y1: y,
          x2: x + barWidth,
          y2: y + barHeight,
          color: img.ColorRgb8(0, 0, 0));

      // Draw label
      img.drawString(image, '1 cm',
          font: img.arial24,
          x: x + 4,
          y: y - 40,
          color: img.ColorRgb8(255, 255, 255));

      final encoded = img.encodeJpg(image);
      await File(path).writeAsBytes(encoded);
      return XFile(path);
    } catch (e) {
      return XFile(path);
    }
  }
}
