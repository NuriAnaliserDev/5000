import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/settings_controller.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsController>();
    final colorScheme = Theme.of(context).colorScheme;

    PageDecoration pageDecoration = PageDecoration(
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

    return IntroductionScreen(
      globalBackgroundColor: Colors.white,
      pages: [
        PageViewModel(
          title: "AI Lithology (Gemini)",
          body: "Vertex AI yordamida tog' jinslarini real-vaqtda tahlil qiling. Textura va mineralogik tarkibni avtomatik aniqlang.",
          image: _buildImage(Icons.psychology_rounded, Colors.purple),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "3D Structural Core",
          body: "Geologik qatlamlarni yer ostidagi holatini 3D proeksiyada vizuallashtiring. AR orqali kelajak xaritasini ko'ring.",
          image: _buildImage(Icons.layers_rounded, Colors.blue),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Professional GIS Export",
          body: "Ma'lumotlarni AutoCAD (DXF), QGIS (GeoJSON) va Google Earth (KML) formatlarida qatlamlar bilan eksport qiling.",
          image: _buildImage(Icons.map_rounded, Colors.green),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Team Collaboration",
          body: "Dala ma'lumotlarini real-vaqtda jamoa bilan sinxronizatsiya qiling. Offline-first texnologiyasi bilan aloqasiz qolmang.",
          image: _buildImage(Icons.groups_rounded, Colors.orange),
          decoration: pageDecoration,
        ),
      ],
      onDone: () {
        settings.isFirstRun = false;
        Navigator.of(context).pushReplacementNamed('/dashboard');
      },
      onSkip: () {
        settings.isFirstRun = false;
        Navigator.of(context).pushReplacementNamed('/dashboard');
      },
      showSkipButton: true,
      skip: const Text("O'tkazib yuborish", style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text("Boshlash", style: TextStyle(fontWeight: FontWeight.w600)),
      curve: Curves.fastLinearToSlowEaseIn,
      dotsDecorator: DotsDecorator(
        size: const Size(10.0, 10.0),
        color: const Color(0xFFBDBDBD),
        activeSize: const Size(22.0, 10.0),
        activeShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
        activeColor: colorScheme.secondary,
      ),
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
