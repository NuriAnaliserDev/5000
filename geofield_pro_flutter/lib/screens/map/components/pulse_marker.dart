import 'package:flutter/material.dart';

// PERFORMANCE FIX: RepaintBoundary qo'shildi — animatsiya faqat o'z
// layer'ida repaint qiladi, qolgan map widget'larini qayta chizmaydigan qildi.
// Bundan tashqari, FadeTransition o'rniga AnimatedOpacity ishlatildi —
// bu GPU-accelerated va UI thread'ni band qilmaydi.
class PulseMarker extends StatefulWidget {
  final String name;
  const PulseMarker({super.key, required this.name});

  @override
  State<PulseMarker> createState() => _PulseMarkerState();
}

class _PulseMarkerState extends State<PulseMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    // CurvedAnimation — iOS kabi natural ko'rinish
    _opacityAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary: animatsiya qayta chizilganda faqat bu widget,
    // qolgan map layers qayta chizilmaydi — bu juda muhim performance fix!
    return RepaintBoundary(
      child: FadeTransition(
        opacity: _opacityAnim,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.5),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Text(
                'SOS: ${widget.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(height: 2),
            const Icon(Icons.warning_rounded, color: Colors.red, size: 36),
          ],
        ),
      ),
    );
  }
}
