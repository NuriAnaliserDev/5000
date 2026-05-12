import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app/app_bootstrap_shell.dart';
import 'app/global_navigator.dart';
import 'core/error/error_mapper.dart';
import 'core/error/error_logger.dart';
//import 'core/error/error_handler.dart'; app qayta qayta dialog chiqarishni oldini oladi. Error handlerga bog`liq
import 'core/error/global_error_handling.dart';
import 'core/diagnostics/startup_telemetry.dart';
import 'core/diagnostics/production_diagnostics.dart';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    StartupTelemetry.onProcessStart();
    configureGlobalErrorHandling();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      final mappedError = ErrorMapper.map(details.exception, details.stack);
      ErrorLogger.log(mappedError);
      if (globalNavigatorKey.currentContext != null) {
        //ErrorHandler.show(globalNavigatorKey.currentContext!, mappedError);
      }
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      final mappedError = ErrorMapper.map(error, stack);
      ErrorLogger.log(mappedError);
      if (globalNavigatorKey.currentContext != null) {
        //ErrorHandler.show(globalNavigatorKey.currentContext!, mappedError);
      }
      return true;
    };

    runApp(const AppBootstrapShell());
  }, (error, stack) {
    final mappedError = ErrorMapper.map(error, stack);
    ErrorLogger.log(mappedError);
    unawaited(
      ProductionDiagnostics.failure(
        'zone_uncaught',
        data: {
          'type': error.runtimeType.toString(),
          'message': error.toString(),
        },
      ),
    );
  });
}
