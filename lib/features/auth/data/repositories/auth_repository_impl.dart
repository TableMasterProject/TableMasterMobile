import 'package:table_master_mobile/core/notification_service.dart';
import 'package:table_master_mobile/core/logging/app_logger.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';
import '../models/login_user_in.dart';
import '../models/login_token_in.dart';
import '../models/login_user_out.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthDataSource remoteDataSource;
  final NotificationService notificationService;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  AuthRepositoryImpl(this.remoteDataSource, this.notificationService);

  @override
  Future<LoginUserOut> login(LoginUserIn credentials) async {
    // 1. Appel API via le DataSource
    final result = await remoteDataSource.login(credentials);

    // 2. Sauvegarde locale des tokens et de l'ID utilisateur
    await _saveTokens(result.accessToken, result.refreshToken);
    await storage.write(key: 'user_id', value: result.user.id.toString());

    // 3. Enregistrement du token Firebase pour les notifications
    try {
      await notificationService.registerTokenForCurrentUser();
    } catch (e) {
      AppLogger.debug("Erreur lors de l'enregistrement du token de notification", e);
    }

    return result;
  }

  @override
  Future<LoginUserOut> refresh(LoginTokenIn tokenIn) async {
    final result = await remoteDataSource.refresh(tokenIn);
    await _saveTokens(result.accessToken, result.refreshToken);
    return result;
  }

  @override
  Future<void> logout() async {
    // 1. Supprimer le token sur le serveur (API DeviceToken)
    try {
      await notificationService.unregisterDeviceToken();
    } catch (e) {
      AppLogger.debug("Erreur lors de la suppression du token de notification", e);
    }

    // 2. Supprime les jetons et l'ID utilisateur du téléphone
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    await storage.delete(key: 'fcm_token');
    await storage.delete(key: 'user_id');
  }

  @override
  Future<bool> isAuthenticated() async {
    String? token = await storage.read(key: 'access_token');
    return token != null;
  }

  Future<void> _saveTokens(String access, String refresh) async {
    await storage.write(key: 'access_token', value: access);
    await storage.write(key: 'refresh_token', value: refresh);
  }
}
