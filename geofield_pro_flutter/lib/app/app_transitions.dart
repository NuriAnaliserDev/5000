import 'package:flutter/material.dart';

/// Marshrutlar o'tishi: engil fade + yengil siljish.
abstract final class AppPageRoutes {
  static const Duration _d = Duration(milliseconds: 260);

  static Route<T> material<T>(WidgetBuilder builder,
      {RouteSettings? settings}) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: _d,
      reverseTransitionDuration: _d,
      pageBuilder: (context, a1, a2) => builder(context),
      transitionsBuilder: (context, animation, secondary, child) {
        final t = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: t,
          child: SlideTransition(
            position:
                Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
                    .animate(t),
            child: child,
          ),
        );
      },
    );
  }
}
