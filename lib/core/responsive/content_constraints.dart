import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Centre et borne la largeur du contenu pour éviter l'étirement sur grand écran.
///
/// À utiliser pour les pages, formulaires, et listes verticales.
class CenteredContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry alignment;

  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.padding,
    this.alignment = Alignment.topCenter,
  });

  /// Variante pour les formulaires (max ~480px).
  const CenteredContent.form({
    super.key,
    required this.child,
    this.padding,
    this.alignment = Alignment.topCenter,
  }) : maxWidth = Breakpoints.maxFormWidth;

  /// Variante pour les listes (max ~1400px).
  const CenteredContent.list({
    super.key,
    required this.child,
    this.padding,
    this.alignment = Alignment.topCenter,
  }) : maxWidth = Breakpoints.maxListWidth;

  /// Variante pour les grilles (max ~1600px).
  const CenteredContent.grid({
    super.key,
    required this.child,
    this.padding,
    this.alignment = Alignment.topCenter,
  }) : maxWidth = Breakpoints.maxGridWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: width < Breakpoints.mobile ? 16 : 24,
          vertical: width < Breakpoints.mobile ? 12 : 16,
        );

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}
