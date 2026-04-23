import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/theme_controller.dart';
import '../utils/security_wrapper.dart';
import 'app_router.dart';

class GeoFieldProApp extends StatelessWidget {
  const GeoFieldProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeCtrl, _) {
        return MaterialApp(
          title: 'GeoField Pro N',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF263238),
              secondary: Color(0xFF1565C0),
              surface: Color(0xFFFFFFFF),
            ),
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFFF5F5F5),
              foregroundColor: Color(0xFF263238),
              elevation: 0,
            ),
            textTheme: GoogleFonts.robotoTextTheme(),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF455A64),
              secondary: Color(0xFF42A5F5),
              surface: Color(0xFF121212),
            ),
            textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
            useMaterial3: true,
          ),
          themeMode: themeCtrl.mode,
          builder: (context, child) {
            return SecurityWrapper(child: child!);
          },
          initialRoute: AppRouter.home,
          onGenerateRoute: AppRouter.onGenerateRoute,
        );
      },
    );
  }
}
