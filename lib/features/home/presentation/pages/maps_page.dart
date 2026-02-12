import 'package:flutter/material.dart';

class MapsPage extends StatelessWidget {
  const MapsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_outlined, size: 80, color: colors.primary),
          const SizedBox(height: 20),
          Text(
            "Consultez la carte des restaurants",
            style: TextStyle(fontSize: 18, color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
