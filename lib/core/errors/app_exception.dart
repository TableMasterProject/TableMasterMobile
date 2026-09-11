import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  factory AppException.fromDio(DioException exception) {
    final response = exception.response;
    if (response == null) {
      return const AppException('Connexion au serveur impossible');
    }
    final status = response.statusCode;
    if (status != null && status >= 500) {
      return AppException('Erreur serveur', statusCode: status);
    }
    final data = response.data;
    final candidate =
        data is Map ? data['error'] ?? data['title'] ?? data['detail'] : data;
    final message =
        candidate is String && _safeMessage(candidate)
            ? candidate.trim()
            : 'Erreur serveur';
    return AppException(message, statusCode: status);
  }

  static bool _safeMessage(String value) =>
      value.trim().isNotEmpty &&
      value.length <= 500 &&
      !RegExp(
        r'[{}<>]|Bearer\s|eyJ[a-zA-Z0-9_-]+\.|(?:password|token|connectionstring)\s*[:=]',
        caseSensitive: false,
      ).hasMatch(value);

  @override
  String toString() => message;
}
