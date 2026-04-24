import 'package:flutter/material.dart';

enum LineKind { tram, sBahn, regional, nightBus, bus, unknown }

class LineBadge extends StatelessWidget {
  const LineBadge({
    super.key,
    required this.line,
    this.compact = false,
  });

  final String line;
  final bool compact;

  static LineKind classify(String line) {
    final upper = line.trim().toUpperCase();
    if (upper.isEmpty) return LineKind.unknown;
    if (RegExp(r'^S\d+').hasMatch(upper)) return LineKind.sBahn;
    if (RegExp(r'^(RE|RB|IC|ICE|EC|IRE)\b').hasMatch(upper)) {
      return LineKind.regional;
    }
    if (RegExp(r'^N\d').hasMatch(upper)) return LineKind.nightBus;
    if (RegExp(r'^\d{1,2}$').hasMatch(upper)) {
      final n = int.tryParse(upper) ?? 0;
      if (n >= 1 && n <= 8) return LineKind.tram;
      return LineKind.bus;
    }
    return LineKind.bus;
  }

  ({Color bg, Color fg}) _palette(BuildContext context, LineKind kind) {
    final scheme = Theme.of(context).colorScheme;
    switch (kind) {
      case LineKind.tram:
        return (bg: const Color(0xFFE20613), fg: Colors.white);
      case LineKind.sBahn:
        return (bg: const Color(0xFF00933B), fg: Colors.white);
      case LineKind.regional:
        return (bg: const Color(0xFFB00020), fg: Colors.white);
      case LineKind.nightBus:
        return (bg: const Color(0xFF4A148C), fg: Colors.white);
      case LineKind.bus:
        return (bg: const Color(0xFF0F6FB0), fg: Colors.white);
      case LineKind.unknown:
        return (bg: scheme.surfaceContainerHighest, fg: scheme.onSurfaceVariant);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = line.trim().isEmpty ? '?' : line.trim();
    final kind = classify(display);
    final palette = _palette(context, kind);

    final hPad = compact ? 8.0 : 10.0;
    final vPad = compact ? 4.0 : 6.0;
    final radius = compact ? 8.0 : 10.0;
    final minWidth = compact ? 36.0 : 44.0;
    final fontSize = compact ? 12.5 : 14.0;

    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(
        display,
        style: theme.textTheme.labelMedium?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: palette.fg,
          height: 1.1,
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
