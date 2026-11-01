import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_master_mobile/features/home/presentation/widgets/discovery_mobile_view.dart';

void main() {
  testWidgets('la liste précède la carte sur téléphone', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DiscoveryMobileView(
            search: const Text('Recherche'),
            list: const Text('Liste des restaurants'),
            map: const Text('Carte des restaurants'),
          ),
        ),
      ),
    );
    expect(find.text('Liste des restaurants'), findsOneWidget);
    expect(find.text('Carte des restaurants'), findsNothing);
    await tester.tap(find.text('Carte'));
    await tester.pumpAndSettle();
    expect(find.text('Carte des restaurants'), findsOneWidget);
  });
}
