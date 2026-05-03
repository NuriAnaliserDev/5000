import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;

// Import conditional implementations
// Ignore the error if the environment doesn't match
import 'web_downloader_stub.dart'
    if (dart.library.html) 'web_downloader_web.dart';

class FileDownloader {
  static Future<void> downloadBytes(List<int> bytes, String fileName) async {
    if (kIsWeb) {
      WebDownloader.downloadFileWeb(bytes, fileName);
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final file = io.File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      // In a real mobile app, you would use 'share_plus' or 'open_file' here to show it to the user.
    }
  }
}
