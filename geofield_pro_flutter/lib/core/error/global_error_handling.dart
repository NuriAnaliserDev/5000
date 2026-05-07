import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../app/global_navigator.dart';
import 'error_logger.dart';
import 'error_mapper.dart';

/// Chiqarish va build bosqichidagi xatolarni ilovani to‘liq qora/yellow ekranga
/// qoldirmasdan chiqarish (production stabilizatsiya).
void configureGlobalErrorHandling() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    ErrorLogger.log(ErrorMapper.map(details.exception, details.stack));
    if (kDebugMode) {
      return ErrorWidget(details.exception);
    }
    return Material(
      color: const Color(0xFF121212),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.broken_image_outlined,
                  color: Colors.white54, size: 48),
              const SizedBox(height: 16),
              Text(
                'Bu qism vaqtincha chiqarilmadi.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 16,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  final nav = globalNavigatorKey.currentState;
                  if (nav != null && nav.canPop()) {
                    nav.pop();
                  }
                },
                child: const Text('Orqaga'),
              ),
            ],
          ),
        ),
      ),
    );
  };
}
