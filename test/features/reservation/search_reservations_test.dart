import 'package:flutter_test/flutter_test.dart';
import 'package:table_master_mobile/features/reservation/data/models/search_reservations.dart';

void main() {
  test('tri décroissant transmis seulement quand demandé', () {
    expect(SearchReservations().toJson().containsKey('SortDescending'), false);
    expect(
      SearchReservations(sortDescending: true).toJson()['SortDescending'],
      true,
    );
  });
}
