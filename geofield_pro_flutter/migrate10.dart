import 'dart:io';

void main() {
  var files = [
    'lib/screens/web/web_map_screen.dart',
    'lib/screens/web/web_login_screen.dart',
    'lib/screens/web/components/web_verification_terminal.dart',
    'lib/screens/station_summary_screen.dart',
    'lib/screens/splash_screen.dart',
    'lib/screens/smart_camera/smart_camera_screen_state.dart',
    'lib/screens/smart_camera/components/camera_top_bar.dart',
    'lib/screens/smart_camera/components/camera_side_controls.dart',
    'lib/screens/scale_assistant_screen.dart',
    'lib/screens/onboarding_screen.dart',
  ];

  for (var path in files) {
    var file = File(path);
    if (!file.existsSync()) continue;
    
    var content = file.readAsStringSync();
    var original = content;

    if (path.contains('web_login_screen.dart')) {
      content = content.replaceAll(
        'Navigator.of(context).pushReplacement(\n      MaterialPageRoute(builder: (_) => const WebDashboardMain()),\n    );',
        'context.go(\'/\');'
      );
    }
    
    content = content.replaceAllMapped(RegExp(r'Navigator\.pop\(([a-zA-Z0-9_]+)\)'), (m) => '${m[1]}.pop()');
    content = content.replaceAllMapped(RegExp(r'Navigator\.pop\(([a-zA-Z0-9_]+),\s*([^)]+)\)'), (m) => '${m[1]}.pop(${m[2]})');
    content = content.replaceAllMapped(RegExp(r'Navigator\.of\(([a-zA-Z0-9_]+)\)\.pop\(\)'), (m) => '${m[1]}.pop()');
    content = content.replaceAllMapped(RegExp(r'Navigator\.of\(([a-zA-Z0-9_]+)\)\.pop\(([^)]+)\)'), (m) => '${m[1]}.pop(${m[2]})');
    content = content.replaceAllMapped(RegExp(r'Navigator\.of\(([a-zA-Z0-9_]+),\s*rootNavigator:\s*true\)\.pop\(\)'), (m) => '${m[1]}.pop()');
    content = content.replaceAllMapped(RegExp(r'Navigator\.of\(([a-zA-Z0-9_]+),\s*rootNavigator:\s*true\)\.pop\(([^)]+)\)'), (m) => '${m[1]}.pop(${m[2]})');
    
    content = content.replaceAllMapped(RegExp(r'Navigator\.pushReplacementNamed\(([a-zA-Z0-9_]+),\s*([^)]+)\)'), (m) => '${m[1]}.go(${m[2]})');
    content = content.replaceAllMapped(RegExp(r'Navigator\.of\(([a-zA-Z0-9_]+)\)\.pushReplacementNamed\(([^)]+)\)'), (m) => '${m[1]}.go(${m[2]})');
    content = content.replaceAllMapped(RegExp(r'Navigator\.of\(([a-zA-Z0-9_]+),\s*rootNavigator:\s*true\)\.pushReplacementNamed\(([^,]+),\s*arguments:\s*([^)]+)\)'), (m) => '${m[1]}.go(${m[2]}, extra: ${m[3]})');
    content = content.replaceAllMapped(RegExp(r'Navigator\.of\(([a-zA-Z0-9_]+),\s*rootNavigator:\s*true\)\.pushReplacementNamed\(([^)]+)\)'), (m) => '${m[1]}.go(${m[2]})');

    content = content.replaceAllMapped(RegExp(r'Navigator\.pushNamed\(([a-zA-Z0-9_]+),\s*([^,]+),\s*arguments:\s*([^)]+)\)'), (m) => '${m[1]}.push(${m[2]}, extra: ${m[3]})');
    content = content.replaceAllMapped(RegExp(r'Navigator\.pushNamed\(([a-zA-Z0-9_]+),\s*([^)]+)\)'), (m) => '${m[1]}.push(${m[2]})');
    content = content.replaceAllMapped(RegExp(r'Navigator\.of\(([a-zA-Z0-9_]+)\)\.pushNamed\(([^,]+),\s*arguments:\s*([^)]+)\)'), (m) => '${m[1]}.push(${m[2]}, extra: ${m[3]})');
    content = content.replaceAllMapped(RegExp(r'Navigator\.of\(([a-zA-Z0-9_]+)\)\.pushNamed\(([^)]+)\)'), (m) => '${m[1]}.push(${m[2]})');
    content = content.replaceAllMapped(RegExp(r'Navigator\.of\(([a-zA-Z0-9_]+),\s*rootNavigator:\s*true\)\.pushNamed\(([^,]+),\s*arguments:\s*([^)]+)\)'), (m) => '${m[1]}.push(${m[2]}, extra: ${m[3]})');
    content = content.replaceAllMapped(RegExp(r'Navigator\.of\(([a-zA-Z0-9_]+),\s*rootNavigator:\s*true\)\.pushNamed\(([^)]+)\)'), (m) => '${m[1]}.push(${m[2]})');

    content = content.replaceAllMapped(RegExp(r'Navigator\.of\(([a-zA-Z0-9_]+)\)\.maybePop\(\)'), (m) => 'if (${m[1]}.canPop()) ${m[1]}.pop()');

    if (!content.contains("package:go_router/go_router.dart") && RegExp(r'\b(context|ctx|c)\.(go|push|pop|canPop)\b').hasMatch(content)) {
      content = content.replaceFirst("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:go_router/go_router.dart';");
    }

    if (original != content) {
      file.writeAsStringSync(content);
      print('Updated $path');
    }
  }
}
