import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/settings_controller.dart';

/// [DraggableFab] — uzun bosib (long-press) ushlab turganda sudralib ko‘chiriladigan
/// floating tugma. Joy (Offset) [SettingsController.setFabPosition] orqali Hive ga
/// saqlanadi va keyingi kirishda tiklanadi.
///
/// Bir vaqtning o‘zida ekranda bir nechta [DraggableFab] ishlatish uchun — har biriga
/// noyob [id] bering (masalan: `map_slice`, `camera_shutter`).
///
/// [defaultOffset] — birinchi ochilishda qo‘llaniladigan koordinata:
/// * `dx > 0` — chapdan masofa; `dx < 0` — o‘ngdan masofa;
/// * `dy > 0` — tepadan; `dy < 0` — pastdan.
///
/// Saqlanishda — har doim absolute `(left, top)` qiymatga aylantiriladi.
class DraggableFab extends StatefulWidget {
  final String screen;
  final String id;
  final Offset defaultOffset;
  final Widget child;
  final Size size;
  final bool enableDrag;

  /// Agar [true] — child ni `SizedBox` ichiga olmaydi, tabiy o‘lchami beriladi.
  /// Bu o‘zgaruvchan balandlikdagi panellarni (masalan, kamera yon paneli) to‘g‘ri
  /// ko‘rsatish uchun kerak. Lekin baribir joylashish uchun [size] ishlatiladi
  /// (clamp qilish uchun). Uzun bosish gesture maydoni [size] bilan belgilanadi.
  final bool unconstrained;

  const DraggableFab({
    super.key,
    required this.screen,
    required this.id,
    required this.defaultOffset,
    required this.child,
    this.size = const Size(56, 56),
    this.enableDrag = true,
    this.unconstrained = false,
  });

  @override
  State<DraggableFab> createState() => _DraggableFabState();
}

class _DraggableFabState extends State<DraggableFab>
    with SingleTickerProviderStateMixin {
  Offset? _savedPos;

  bool _dragging = false;
  Offset _dragStart = Offset.zero;
  Offset _dragCurrent = Offset.zero;

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    lowerBound: 0.94,
    upperBound: 1.10,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final settings = context.read<SettingsController>();
      final saved = settings.getFabPosition(widget.screen, widget.id);
      if (saved != null && mounted) {
        setState(() => _savedPos = saved);
      }
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Offset _resolveInitialPosition(Size screen) {
    if (_savedPos != null) return _savedPos!;
    final d = widget.defaultOffset;
    final dx = d.dx >= 0 ? d.dx : (screen.width - widget.size.width + d.dx);
    final dy = d.dy >= 0 ? d.dy : (screen.height - widget.size.height + d.dy);
    return Offset(
      dx.clamp(4.0, screen.width - widget.size.width - 4.0),
      dy.clamp(4.0, screen.height - widget.size.height - 4.0),
    );
  }

  void _onLongPressStart(Offset basePos) {
    HapticFeedback.mediumImpact();
    _dragStart = basePos;
    _dragCurrent = basePos;
    _pulseCtrl.repeat(reverse: true);
    setState(() => _dragging = true);
  }

  void _onLongPressMove(LongPressMoveUpdateDetails d, Size screen) {
    if (!_dragging) return;
    final next = _dragStart + d.offsetFromOrigin;
    final clamped = Offset(
      next.dx.clamp(4.0, screen.width - widget.size.width - 4.0),
      next.dy.clamp(4.0, screen.height - widget.size.height - 4.0),
    );
    setState(() => _dragCurrent = clamped);
  }

  void _onLongPressEnd() {
    if (!_dragging) return;
    HapticFeedback.selectionClick();
    _pulseCtrl.stop();
    _pulseCtrl.value = 1.0;
    final finalPos = _dragCurrent;
    context
        .read<SettingsController>()
        .setFabPosition(widget.screen, widget.id, finalPos);
    setState(() {
      _savedPos = finalPos;
      _dragging = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = Size(constraints.maxWidth, constraints.maxHeight);
        final base = _resolveInitialPosition(screen);
        final pos = _dragging ? _dragCurrent : base;

        final inner = widget.unconstrained
            ? _wrapVisual(widget.child)
            : SizedBox(
                width: widget.size.width,
                height: widget.size.height,
                child: _wrapVisual(widget.child),
              );

        return Stack(
          children: [
            Positioned(
              left: pos.dx,
              top: pos.dy,
              child: widget.enableDrag
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onLongPressStart: (_) => _onLongPressStart(base),
                      onLongPressMoveUpdate: (d) => _onLongPressMove(d, screen),
                      onLongPressEnd: (_) => _onLongPressEnd(),
                      child: inner,
                    )
                  : inner,
            ),
          ],
        );
      },
    );
  }

  Widget _wrapVisual(Widget child) {
    if (!_dragging) return child;
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, c) {
        return Transform.scale(
          scale: _pulseCtrl.value,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF1976D2).withValues(alpha: 0.25),
                  border: Border.all(
                    color: const Color(0xFF1976D2),
                    width: 2,
                  ),
                ),
              ),
              c!,
            ],
          ),
        );
      },
      child: child,
    );
  }
}

/// Bir nechta [DraggableFab] ni Stack ichida birlashtirish uchun konteyner.
/// Barcha fab lar screen o‘lchamidan foydalanishi uchun shu konteyner ichidan
/// tarqatilishi kerak (Positioned.fill).
class DraggableFabLayer extends StatelessWidget {
  final List<Widget> children;
  const DraggableFabLayer({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(children: children),
      ),
    );
  }
}
