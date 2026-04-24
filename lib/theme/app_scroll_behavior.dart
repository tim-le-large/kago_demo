import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Allows dragging scrollables with mouse / trackpad (e.g. Flutter web).
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}
