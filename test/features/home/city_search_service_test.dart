import 'package:flutter_test/flutter_test.dart';
import 'package:table_master_mobile/features/home/data/city_search_service.dart';

void main() {
  test('commune center uses longitude then latitude from Geo API', () {
    final city = CitySuggestion.fromJson({
      'nom': 'Lyon',
      'code': '69123',
      'codeDepartement': '69',
      'centre': {
        'coordinates': [4.8351, 45.758],
      },
    });

    expect(city.name, 'Lyon');
    expect(city.center.latitude, 45.758);
    expect(city.center.longitude, 4.8351);
  });

  test('commune without coordinates is ignored', () {
    expect(CitySuggestion.tryFromJson({'nom': 'Inconnue'}), isNull);
  });
}
