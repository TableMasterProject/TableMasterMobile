import 'package:flutter_test/flutter_test.dart';
import 'package:table_master_mobile/features/home/presentation/home_navigation.dart';

void main() {
  test('un restaurateur arrive sur Service avec trois destinations', () {
    final navigation = HomeNavigation.forAccountType(1);

    expect(navigation.initialIndex, 0);
    expect(navigation.labels, ['Service', 'Tables', 'Compte']);
  });

  test('un client arrive sur Découvrir avec ses réservations', () {
    final navigation = HomeNavigation.forAccountType(0);

    expect(navigation.initialIndex, 0);
    expect(navigation.labels, ['Découvrir', 'Mes réservations', 'Compte']);
  });
}
