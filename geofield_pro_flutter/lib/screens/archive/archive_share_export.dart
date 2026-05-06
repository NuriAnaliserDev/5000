import 'dart:io';

import 'package:share_plus/share_plus.dart';

Future<void> archiveShareExportFile(File file) async {
  await Share.shareXFiles([XFile(file.path)], text: 'GeoField Pro N Export');
}
