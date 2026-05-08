import 'package:dio/dio.dart';

class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  factory AppException.fromDio(DioException exception) {
    final response = exception.response;
    if (response == null) {
      return const AppException("Connexion au serveur impossible");
    }

    final data = response.data;
    final message = data == null || data.toString().trim().isEmpty
        ? "Erreur serveur"
        : data.toString();

    return AppException(message, statusCode: response.statusCode);
  }

  @override
  String toString() => message;
}
