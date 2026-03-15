import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.accent,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: AppTheme.glowCard(accent: accent),
      padding: padding,
      child: child,
    );
    if (margin == null) return card;
    return Padding(padding: margin!, child: card);
  }
}
