import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in dartFiles) {
    String content = file.readAsStringSync();
    bool changed = false;

    // Replace ErrorHandler.show(context, e) with ErrorHandler.show(context, ErrorMapper.map(e))
    // We handle e and e, st variants.
    if (content.contains('ErrorHandler.show(')) {
      content = content.replaceAllMapped(
          RegExp(r'ErrorHandler\.show\((context),\s*([a-zA-Z_0-9]+)\s*\);'),
          (match) =>
              'ErrorHandler.show(${match[1]}, ErrorMapper.map(${match[2]}));');
      content = content.replaceAllMapped(
          RegExp(
              r'ErrorHandler\.show\((context),\s*([a-zA-Z_0-9]+),\s*([a-zA-Z_0-9]+)\s*\);'),
          (match) =>
              'ErrorHandler.show(${match[1]}, ErrorMapper.map(${match[2]}, ${match[3]}));');

      // Ensure import
      if (!content.contains('error_mapper.dart')) {
        // Find ErrorHandler import and inject Mapper import
        content = content.replaceFirstMapped(
            RegExp(r"import '([^']+?)error_handler\.dart';"),
            (m) =>
                "import '${m[1]}error_handler.dart';\nimport '${m[1]}error_mapper.dart';");
      }
      changed = true;
    }

    if (changed) {
      file.writeAsStringSync(content);
      print('Updated: ${file.path}');
    }
  }
}
