import 'dart:io' show Directory, File, stdout;

void main() {
  final dir = Directory('lib');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
  for (final file in files) {
    var content = file.readAsStringSync();
    if (content.contains('GeoField Pro (N)')) {
      content = content.replaceAll('GeoField Pro (N)', 'GeoField Pro N');
      file.writeAsStringSync(content);
      stdout.writeln('Updated ${file.path}');
    }
  }
}
