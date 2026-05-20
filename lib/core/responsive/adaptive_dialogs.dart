import 'package:flutter/material.dart';

import 'breakpoints.dart';

/// Affiche un panneau modal adapté à la plateforme : bottom-sheet sur mobile,
/// dialog centré sur tablet/desktop.
Future<T?> showAdaptiveSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  double dialogMaxWidth = 560,
}) {
  if (context.isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      showDragHandle: true,
      builder: builder,
    );
  }

  return showDialog<T>(
    context: context,
    builder: (ctx) {
      return Dialog(
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: dialogMaxWidth,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.85,
          ),
          child: builder(ctx),
        ),
      );
    },
  );
}
