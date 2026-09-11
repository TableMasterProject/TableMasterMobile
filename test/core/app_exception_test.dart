import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:table_master_mobile/core/errors/app_exception.dart';

void main() {
  AppException parse(Object data, [int code = 400]) => AppException.fromDio(
    DioException(
      requestOptions: RequestOptions(),
      response: Response(
        requestOptions: RequestOptions(),
        data: data,
        statusCode: code,
      ),
    ),
  );
  test('affiche seulement le message error sans trace ni données annexes', () {
    expect(
      parse({
        'error': 'Conflit de réservation',
        'traceId': 'internal',
        'token': 'private',
      }).message,
      'Conflit de réservation',
    );
  });
  test('lit les problem details et chaînes sans convertir une map brute', () {
    expect(
      parse({'title': 'Requête invalide', 'traceId': 'internal'}).message,
      'Requête invalide',
    );
    expect(parse('Session expirée').message, 'Session expirée');
    expect(parse({'password': 'private'}).message, 'Erreur serveur');
  });
  test('une erreur 500 ne montre pas les détails internes', () {
    expect(
      parse('SqlException: private connection', 500).message,
      'Erreur serveur',
    );
  });
}
