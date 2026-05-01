import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../services/settings_controller.dart';
import '../services/theme_controller.dart';
import '../utils/firebase_ready.dart';
import '../utils/security_wrapper.dart';
import 'app_router.dart';
import 'app_theme.dart';

String _appLocaleCode(String? code) {
  const ok = <String>['en', 'tr', 'uz'];
  if (code == null || !ok.contains(code)) return 'en';
  return code;
}

class GeoFieldProApp extends StatelessWidget {
  const GeoFieldProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeController, SettingsController>(
      builder: (context, themeCtrl, settings, _) {
        return MaterialApp(
          locale: Locale(_appLocaleCode(settings.language)),
          onGenerateTitle: (context) => GeoFieldStrings.of(context)!.app_title,
          localizationsDelegates: GeoFieldStrings.localizationsDelegates,
          supportedLocales: GeoFieldStrings.supportedLocales,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeCtrl.mode,
          builder: (context, child) {
            final cloudOk =
                context.watch<FirebaseBootstrapState>().isCloudEnabled;
            return SecurityWrapper(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!cloudOk)
                    Material(
                      color: const Color(0xFFE65100),
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Text(
                            GeoFieldStrings.of(context)
                                    ?.firebase_local_only_banner ??
                                'Local mode: cloud unavailable.',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                            ),
                          ),
                        ),
                      ),
                    ),
                  Expanded(child: child ?? const SizedBox.shrink()),
                ],
              ),
            );
          },
          initialRoute: AppRouter.home,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
