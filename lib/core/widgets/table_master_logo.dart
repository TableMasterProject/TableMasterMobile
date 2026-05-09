import 'package:flutter/material.dart';

class TableMasterLogo extends StatelessWidget {
  final double size;
  final bool showText;

  const TableMasterLogo({super.key, this.size = 140, this.showText = true});

  @override
  Widget build(BuildContext context) {
    final logo = Image.asset(
      'assets/branding/tablemaster_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );

    if (!showText) {
      return logo;
    }

    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        logo,
        const SizedBox(height: 10),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'TableMaster',
            maxLines: 1,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}
