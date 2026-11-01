import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CitySuggestion {
  const CitySuggestion({
    required this.name,
    required this.code,
    required this.department,
    required this.center,
  });

  final String name;
  final String code;
  final String department;
  final LatLng center;

  String get label => '$name ($department)';

  factory CitySuggestion.fromJson(Map<String, dynamic> json) =>
      tryFromJson(json) ?? (throw const FormatException('Commune sans centre'));

  static CitySuggestion? tryFromJson(Map<String, dynamic> json) {
    final coordinates = (json['centre'] as Map?)?['coordinates'];
    if (coordinates is! List ||
        coordinates.length < 2 ||
        coordinates[0] is! num ||
        coordinates[1] is! num) {
      return null;
    }
    return CitySuggestion(
      name: json['nom']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      department: json['codeDepartement']?.toString() ?? '',
      center: LatLng(
        (coordinates[1] as num).toDouble(),
        (coordinates[0] as num).toDouble(),
      ),
    );
  }
}

class CitySearchService {
  CitySearchService({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: 'https://geo.api.gouv.fr'));

  final Dio _dio;

  Future<List<CitySuggestion>> search(String input) async {
    final query = input.trim();
    if (query.length < 2) return [];
    final isPostalCode = RegExp(r'^\d{2,5}$').hasMatch(query);
    final response = await _dio.get<List<dynamic>>(
      '/communes',
      queryParameters: {
        isPostalCode ? 'codePostal' : 'nom': query,
        'fields': 'nom,code,codeDepartement,centre',
        'format': 'json',
        'geometry': 'centre',
        'boost': 'population',
        'limit': 8,
      },
    );
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CitySuggestion.tryFromJson)
        .whereType<CitySuggestion>()
        .toList();
  }
}
