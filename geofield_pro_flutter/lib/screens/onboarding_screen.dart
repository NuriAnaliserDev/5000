import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:provider/provider.dart';

import '../app/app_router.dart';
import '../services/settings_controller.dart';
import '../services/user_flags_service.dart';
import '../app/platform_gate.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsController>();
    final colorScheme = Theme.of(context).colorScheme;

    final pageDecoration = PageDecoration(
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 28.0,
        fontWeight: FontWeight.bold,
        color: colorScheme.primary,
      ),
      bodyTextStyle: GoogleFonts.roboto(
        fontSize: 16.0,
        color: Colors.grey[700],
      ),
      bodyPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    Future<void> completeOnboarding() async {
      settings.isFirstRun = false;

      final u = FirebaseAuth.instance.currentUser;

      if (u != null) {
        await UserFlagsService.setOnboardingCompleted(u.uid, true);
      }

      if (!context.mounted) return;

      if (!kIsWeb && isDesktopExe()) {
        context.go(AppRouter.dashboard);
      } else if (u != null) {
        context.go(AppRouter.dashboard);
      } else {
        context.go(AppRouter.auth);
      }
    }

    return IntroductionScreen(
      globalBackgroundColor: Colors.white,
      pages: [
        PageViewModel(
          title: "AI Lithology (Gemini)",
          body:
              "Vertex AI yordamida tog' jinslarini real-vaqtda tahlil qiling.",
          image: _buildImage(Icons.psychology_rounded, Colors.purple),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "3D Structural Core",
          body:
              "Geologik qatlamlarni yer ostidagi holatini 3D ko‘rinishda tahlil qiling.",
          image: _buildImage(Icons.layers_rounded, Colors.blue),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Professional GIS Export",
          body: "DXF, GeoJSON va KML formatlarda professional eksport qiling.",
          image: _buildImage(Icons.map_rounded, Colors.green),
          decoration: pageDecoration,
        ),
      ],
      onDone: completeOnboarding,
      onSkip: completeOnboarding,
      showSkipButton: true,
      skip: const Text("O'tkazib yuborish"),
      next: const Icon(Icons.arrow_forward),
      done: const Text("Boshlash"),
    );
  }

  Widget _buildImage(IconData icon, Color color) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          icon,
          size: 140,
          color: color,
        ),
      ),
    );
  }
}
