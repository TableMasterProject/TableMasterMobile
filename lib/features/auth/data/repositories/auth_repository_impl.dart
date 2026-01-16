import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';
import '../models/login_user_in.dart';
import '../models/login_token_in.dart';
import '../models/login_user_out.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthDataSource remoteDataSource;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<LoginUserOut> login(LoginUserIn credentials) async {
    // 1. Appel API via le DataSource
    final result = await remoteDataSource.login(credentials);

    // 2. Sauvegarde locale des tokens pour rester connecté
    await _saveTokens(result.accessToken, result.refreshToken);

    return result;
  }

  @override
  Future<LoginUserOut> refresh(LoginTokenIn tokenIn) async {
    final result = await remoteDataSource.refresh(tokenIn);

    // Mise à jour des tokens après rafraîchissement
    await _saveTokens(result.accessToken, result.refreshToken);

    return result;
  }

  @override
  Future<void> logout() async {
    // Supprime les jetons du téléphone
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
  }

  @override
  Future<bool> isAuthenticated() async {
    // Vérifie si un jeton existe
    String? token = await storage.read(key: 'access_token');
    return token != null;
  }

  // --- Méthodes privées ---

  Future<void> _saveTokens(String access, String refresh) async {
    await storage.write(key: 'access_token', value: access);
    await storage.write(key: 'refresh_token', value: refresh);
  }
}