import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app/app_bootstrap_shell.dart';
import 'core/error/error_mapper.dart';
import 'core/error/error_logger.dart';
import 'core/error/error_handler.dart';

final GlobalKey<NavigatorState> globalNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      final mappedError = ErrorMapper.map(details.exception, details.stack);
      ErrorLogger.log(mappedError);
      if (globalNavigatorKey.currentContext != null) {
        ErrorHandler.show(globalNavigatorKey.currentContext!, mappedError);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      final mappedError = ErrorMapper.map(error, stack);
      ErrorLogger.log(mappedError);
      if (globalNavigatorKey.currentContext != null) {
        ErrorHandler.show(globalNavigatorKey.currentContext!, mappedError);
      }
      return true;
    };

    runApp(const AppBootstrapShell());
  }, (error, stack) {
    final mappedError = ErrorMapper.map(error, stack);
    ErrorLogger.log(mappedError);
  });
}
