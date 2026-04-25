import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../services/settings_controller.dart';

/// Qanday qilib drag-rejimni boshqarish kerakligi.
enum DragTriggerMode {
  /// Default: uzoq bosish (long-press) bilan sudrab joylashtirish.
  longPress,

  /// Uch marta tez bosish (triple-tap) bilan drag-rejim yoqiladi, keyin
  /// [_armedHoldDuration] ichida oddiy pan (sudrab qo‘yish) bilan joylashtirish
  /// mumkin. Tugmada o‘zining `onLongPress` bor bo‘lsa (masalan, SOS) ushbu
  /// rejim mos keladi.
  tripleTap,
}

/// [DraggableFab] — har xil floating tugmalarni joylashtirish uchun sudrab
/// ko‘chiriladigan konteyner. Pozitsiya [SettingsController.setFabPosition]
/// orqali Hive ga saqlanadi va keyingi kirishda tiklanadi.
///
/// Bir vaqtning o‘zida ekranda bir nechta [DraggableFab] ishlatish uchun — har
/// biriga noyob [id] bering (masalan: `map_slice`, `camera_shutter`).
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
  final DragTriggerMode dragMode;

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
    this.dragMode = DragTriggerMode.longPress,
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

  // Triple-tap uchun
  int _tapCount = 0;
  Timer? _tapResetTimer;
  bool _armed = false;
  Timer? _armedTimer;

  /// Dispose paytida `context` ga murojaat qilmaslik uchun cache.
  SettingsController? _settingsRef;

  static const Duration _tapWindow = Duration(milliseconds: 650);
  static const Duration _armedHoldDuration = Duration(seconds: 6);

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
      _settingsRef = settings;
      final saved = settings.getFabPosition(widget.screen, widget.id);
      if (saved != null && mounted) {
        setState(() => _savedPos = saved);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settingsRef = context.read<SettingsController>();
  }

  @override
  void dispose() {
    _tapResetTimer?.cancel();
    _armedTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _savePosition(Offset pos) {
    try {
      _settingsRef?.setFabPosition(widget.screen, widget.id, pos);
    } catch (_) {
      // ignore: dispose-holatida saqlashda xato bo‘lsa e’tiborsiz qoldiramiz
    }
  }

  /// `clamp(4.0, maxX)` chaqiruvi assertion tashlamasligi uchun xavfsiz klamp.
  /// Agar screen hali berilmagan yoki tugma screen'dan katta bo‘lsa —
  /// `lower > upper` bo‘lib qoladi va `clamp` throw qiladi.
  double _safeClamp(double value, double lower, double upper) {
    if (upper < lower) return lower;
    if (value < lower) return lower;
    if (value > upper) return upper;
    return value;
  }

  Offset _resolveInitialPosition(Size screen) {
    if (_savedPos != null) {
      return Offset(
        _safeClamp(_savedPos!.dx, 4.0, screen.width - widget.size.width - 4.0),
        _safeClamp(_savedPos!.dy, 4.0, screen.height - widget.size.height - 4.0),
      );
    }
    final d = widget.defaultOffset;
    final dx = d.dx >= 0 ? d.dx : (screen.width - widget.size.width + d.dx);
    final dy = d.dy >= 0 ? d.dy : (screen.height - widget.size.height + d.dy);
    return Offset(
      _safeClamp(dx, 4.0, screen.width - widget.size.width - 4.0),
      _safeClamp(dy, 4.0, screen.height - widget.size.height - 4.0),
    );
  }

  // ─────────── Long-press rejim ────────────
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
      _safeClamp(next.dx, 4.0, screen.width - widget.size.width - 4.0),
      _safeClamp(next.dy, 4.0, screen.height - widget.size.height - 4.0),
    );
    setState(() => _dragCurrent = clamped);
  }

  void _onLongPressEnd() {
    if (!_dragging) return;
    HapticFeedback.selectionClick();
    _pulseCtrl.stop();
    _pulseCtrl.value = 1.0;
    final finalPos = _dragCurrent;
    _savePosition(finalPos);
    setState(() {
      _savedPos = finalPos;
      _dragging = false;
    });
  }

  // ─────────── Triple-tap rejim ────────────
  void _onTap() {
    if (widget.dragMode != DragTriggerMode.tripleTap) return;
    if (_dragging) return;
    if (_armed) {
      // Armed holatida tap — boshqa vazifasi yo‘q, taymerni uzaytiramiz.
      _resetArmedTimer();
      return;
    }
    HapticFeedback.selectionClick();
    _tapCount++;
    _tapResetTimer?.cancel();
    _tapResetTimer = Timer(_tapWindow, () {
      _tapCount = 0;
    });
    if (_tapCount >= 3) {
      _tapCount = 0;
      _tapResetTimer?.cancel();
      _armDrag();
    }
  }

  void _armDrag() {
    HapticFeedback.heavyImpact();
    if (mounted) {
      final msg = GeoFieldStrings.of(context)?.map_drag_mode_hint ??
          'Drag mode: slide the button to its new position (6 seconds)';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
    setState(() => _armed = true);
    _pulseCtrl.repeat(reverse: true);
    _resetArmedTimer();
  }

  void _resetArmedTimer() {
    _armedTimer?.cancel();
    _armedTimer = Timer(_armedHoldDuration, _disarmDrag);
  }

  void _disarmDrag() {
    if (!mounted) return;
    _armedTimer?.cancel();
    if (!_dragging) {
      _pulseCtrl.stop();
      _pulseCtrl.value = 1.0;
    }
    setState(() => _armed = false);
  }

  void _onPanStart(Offset basePos) {
    if (!_armed) return;
    _armedTimer?.cancel();
    HapticFeedback.mediumImpact();
    _dragStart = basePos;
    _dragCurrent = basePos;
    setState(() => _dragging = true);
  }

  void _onPanUpdate(DragUpdateDetails d, Size screen) {
    if (!_dragging) return;
    final next = _dragCurrent + d.delta;
    final clamped = Offset(
      _safeClamp(next.dx, 4.0, screen.width - widget.size.width - 4.0),
      _safeClamp(next.dy, 4.0, screen.height - widget.size.height - 4.0),
    );
    setState(() => _dragCurrent = clamped);
  }

  void _onPanEnd() {
    if (!_dragging) return;
    HapticFeedback.selectionClick();
    final finalPos = _dragCurrent;
    _savePosition(finalPos);
    setState(() {
      _savedPos = finalPos;
      _dragging = false;
    });
    _disarmDrag();
  }

  Widget _buildGestureLayer(Widget inner, Offset base, Size screen) {
    if (!widget.enableDrag) return inner;

    if (widget.dragMode == DragTriggerMode.tripleTap) {
      // Armed holatida child ichidagi gesturelarni (masalan, SOS onLongPress)
      // bloklaymiz — shunda faqat bizning pan gesture ishlaydi.
      final child = _armed ? AbsorbPointer(absorbing: true, child: inner) : inner;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        onPanStart: _armed ? (_) => _onPanStart(base) : null,
        onPanUpdate: _armed ? (d) => _onPanUpdate(d, screen) : null,
        onPanEnd: _armed ? (_) => _onPanEnd() : null,
        child: child,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPressStart: (_) => _onLongPressStart(base),
      onLongPressMoveUpdate: (d) => _onLongPressMove(d, screen),
      onLongPressEnd: (_) => _onLongPressEnd(),
      child: inner,
    );
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
              child: _buildGestureLayer(inner, base, screen),
            ),
          ],
        );
      },
    );
  }

  Widget _wrapVisual(Widget child) {
    final active = _dragging || _armed;
    if (!active) return child;
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
