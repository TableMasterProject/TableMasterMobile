import 'package:dio/dio.dart';
import 'package:table_master_mobile/core/notification_service.dart';
import 'package:table_master_mobile/core/logging/app_logger.dart';
import 'package:table_master_mobile/core/signalr_service.dart';
import 'package:table_master_mobile/core/session/session_service.dart';
import 'package:table_master_mobile/core/errors/app_exception.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_datasource.dart';
import '../models/login_user_in.dart';
import '../models/login_token_in.dart';
import '../models/login_user_out.dart';

class AuthRepositoryImpl implements IAuthRepository {
  final AuthDataSource remoteDataSource;
  final NotificationService notificationService;
  final SignalRService signalRService;
  final SessionService? _session;
  SessionService get session => _session ?? remoteDataSource.apiClient.session;

  AuthRepositoryImpl(
    this.remoteDataSource,
    this.notificationService,
    this.signalRService, {
    SessionService? session,
  }) : _session = session;

  @override
  Future<LoginUserOut> login(LoginUserIn credentials) async {
    final result = await remoteDataSource.login(credentials);
    await session.storeSession(result);
    try {
      await notificationService.registerTokenForCurrentUser();
    } catch (error) {
      AppLogger.debug('Erreur enregistrement des notifications', error);
    }
    return result;
  }

  @override
  Future<LoginUserOut> refresh(LoginTokenIn tokenIn) async {
    // La paire courante est lue au début du single flight, jamais depuis un DTO
    // potentiellement périmé fourni par un ancien écran.
    try {
      return await session.refresh();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }

  @override
  Future<void> forgotPassword(String email) =>
      remoteDataSource.forgotPassword(email);
  @override
  Future<void> resetPassword(String token, String newPassword) =>
      remoteDataSource.resetPassword(token, newPassword);

  @override
  Future<void> logout() async {
    // Le nettoyage local invalide immédiatement tous les refresh en vol. Les
    // appels suivants utilisent l'instantané révoqué et ne peuvent rafraîchir.
    final previous = await session.clear();
    try {
      await notificationService.unregisterDeviceToken(
        deviceToken: previous.deviceToken,
        accessToken: previous.accessToken,
      );
    } catch (error) {
      AppLogger.debug('Erreur suppression des notifications', error);
    }
    if (previous.refreshToken != null && previous.accessToken != null) {
      try {
        await remoteDataSource.logout(
          previous.refreshToken!,
          accessToken: previous.accessToken,
        );
      } catch (error) {
        AppLogger.debug('Erreur révocation de session', error);
      }
    }
  }

  @override
  Future<bool> isAuthenticated() async => await session.accessToken != null;
}
