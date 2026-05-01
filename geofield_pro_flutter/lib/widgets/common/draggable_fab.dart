import 'package:flutter/material.dart';

/// Xarita / kamera ustidagi suzuvchi tugmalar — faqat [defaultOffset] bo‘yicha
/// joylashadi (foydalanuvchi sudrab o‘zgartira olmaydi).
class DraggableFab extends StatelessWidget {
  final Offset defaultOffset;
  final Widget child;
  final Size size;

  /// [true] bo‘lsa, [child] tabiiy o‘lchamda; pozitsiya clamp uchun [size] ishlatiladi.
  final bool unconstrained;

  const DraggableFab({
    super.key,
    required this.defaultOffset,
    required this.child,
    this.size = const Size(56, 56),
    this.unconstrained = false,
  });

  double _safeClamp(double value, double lower, double upper) {
    if (upper < lower) return lower;
    if (value < lower) return lower;
    if (value > upper) return upper;
    return value;
  }

  Offset _resolvePosition(Size screen) {
    final d = defaultOffset;
    final dx = d.dx >= 0 ? d.dx : (screen.width - size.width + d.dx);
    final dy = d.dy >= 0 ? d.dy : (screen.height - size.height + d.dy);
    return Offset(
      _safeClamp(dx, 4.0, screen.width - size.width - 4.0),
      _safeClamp(dy, 4.0, screen.height - size.height - 4.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screen = Size(constraints.maxWidth, constraints.maxHeight);
        final pos = _resolvePosition(screen);
        final content = unconstrained
            ? child
            : SizedBox(
                width: size.width,
                height: size.height,
                child: child,
              );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(left: pos.dx, top: pos.dy, child: content),
          ],
        );
      },
    );
  }
}

/// Bir nechta [DraggableFab] ni Stack ichida birlashtirish (z-order tartibi).
class DraggableFabLayer extends StatelessWidget {
  final List<Widget> children;

  const DraggableFabLayer({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        clipBehavior: Clip.none,
        children: children,
      ),
    );
  }
}
