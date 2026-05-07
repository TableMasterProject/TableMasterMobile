# 🔧 Instructions Copilot - TableMasterMobile

**Dernière mise à jour:** 7 mai 2026  
**Framework:** Flutter 3.7.0+  
**Langage:** Dart  
**Locales:** Français (fr_FR)  
**Architecture:** Clean Architecture (Domain/Data/Presentation)

---

## 📋 Table des matières

1. [Stack Technologique](#stack-technologique)
2. [Architecture & Patterns](#architecture--patterns)
3. [Conventions de Code](#conventions-de-code)
4. [Structure des Dossiers](#structure-des-dossiers)
5. [Instructions de Réponse](#instructions-de-réponse)
6. [Composants Clés](#composants-clés)
7. [API Client & HTTP](#api-client--http)

---

## 📚 Stack Technologique

### Framework & Runtimes
- **Framework:** Flutter 3.7.0+
- **Langage:** Dart 3.5.0+
- **Plateforme:** Android (API 21+), iOS (11.0+), Web

### Dépendances Clés

| Paquet | Version | Rôle |
|--------|---------|------|
| **firebase_core** | 4.6.0 | Initialisation Firebase |
| **firebase_messaging** | 16.1.3 | Notifications push FCM |
| **flutter_local_notifications** | 21.0.0 | Notifications locales |
| **dio** | 5.9.0 | HTTP client (REST API) |
| **get_it** | 9.2.0 | Service Locator (DI) |
| **flutter_secure_storage** | 10.0.0 | Stockage sécurisé tokens |
| **intl** | 0.20.2 | Internationalisation (i18n) |
| **google_maps_flutter** | 2.15.0 | Cartes Google |
| **geolocator** | 14.0.2 | Géolocalisation GPS |
| **signalr_netcore** | 1.4.4 | WebSocket SignalR |
| **audioplayers** | 6.6.0 | Lecture audio (notifications) |
| **url_launcher** | 6.3.1 | Ouverture URLs externes |
| **confetti** | 0.8.0 | Animations confettis |
| **flutter_lints** | 5.0.0 | Linting (analyse statique) |

### Configuration & Assets
- **Config Multi-Environnement:**
  - `config/dev.json` → Développement local
  - `config/android-emulate-dev.json` → Émulateur Android
  - `config/prod.json` → Production
- **Firebase:** `firebase.json`, `google-services.json` (Android), `GoogleService-Info.plist` (iOS)
- **Assets:** `assets/sounds/notification.mp3`

### Linting & Analyse
- **Analysis Options:** `analysis_options.yaml`
- **DevTools Options:** `devtools_options.yaml`
- **Pubspec:** Gestion des dépendances

---

## 🏗️ Architecture & Patterns

### Clean Architecture (Domain-Driven)

```
lib/
├── core/                      # Infrastructure partagée
├── features/                  # Domaines métier isolés
│   ├── auth/
│   │   ├── domain/           # Interfaces (contrats)
│   │   ├── data/             # Implémentations
│   │   └── presentation/     # UI / Écrans
│   ├── restaurant/
│   ├── reservation/
│   └── ...
```

#### Couches

**1. Presentation Layer** (`presentation/`)
- Widgets stateful/stateless
- Gestion d'état (Provider, BLoC, GetX)
- Navigation
- **Convention:** `*_screen.dart`, `*_widget.dart`

**2. Domain Layer** (`domain/`)
- Interfaces repository (`abstract class IRepository`)
- Modèles métier (entities)
- Use cases (optionnel, pour logique complexe)
- **Convention:** Interfaces nommées `I*Repository`

**3. Data Layer** (`data/`)
- Implémentations repository (`*RepositoryImpl`)
- Data sources (local/remote)
- Mappers (DTO → Entity)
- **Convention:** `*RepositoryImpl`, `*DataSource`

#### Séparation des Responsabilités

```
Presentation Layer (UI)
    ↓ (appelle)
Domain Layer (Interfaces)
    ↓ (implémente)
Data Layer (API/Local Storage)
    ↓
External Services (Firebase, API, GPS)
```

### Patterns d'Architecture

#### 1. **Repository Pattern**
Chaque domaine expose une interface, pas une implémentation directe.

```dart
// domain/repositories/user_repository.dart
abstract class IUserRepository {
  Future<UserEntity?> getUserById(long id);
  Future<void> updateUser(UserEntity user);
}

// data/repositories/user_repository_impl.dart
class UserRepositoryImpl implements IUserRepository {
  final ApiClient _apiClient;
  
  UserRepositoryImpl(this._apiClient);
  
  @override
  Future<UserEntity?> getUserById(long id) async {
    final dto = await _apiClient.get('/user/$id');
    return UserMapper.toEntity(dto);
  }
}
```

#### 2. **Service Locator (GetIt)**
Gestion centralisée des dépendances via un conteneur.

```dart
// core/injection.dart
final getIt = GetIt.instance;

void setupDependencies() {
  // Services
  getIt.registerSingleton(ApiClient());
  getIt.registerSingleton(NotificationService());
  getIt.registerSingleton(SignalRService());
  
  // Repositories
  getIt.registerSingleton<IAuthRepository>(AuthRepositoryImpl(getIt<ApiClient>()));
  getIt.registerSingleton<IUserRepository>(UserRepositoryImpl(getIt<ApiClient>()));
  getIt.registerSingleton<IRestaurantRepository>(RestaurantRepositoryImpl(getIt<ApiClient>()));
  
  // Controllers/Providers
  getIt.registerSingleton(AuthNotifier(getIt<IAuthRepository>()));
}

// Utilisation
final authRepo = getIt<IAuthRepository>();
```

#### 3. **API Client with Interceptors**
Dio pour HTTP avec gestion des tokens et refresh automatique.

```dart
// core/api_client.dart
class ApiClient {
  late Dio _dio;
  
  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiUrl + "/api",
      connectTimeout: Duration(seconds: 10),
      headers: {'x-api-version': '1.0'},
    ));
    
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Ajouter le token d'accès
          final token = await _getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          // Refresh token si 401
          if (e.response?.statusCode == 401) {
            await _refreshToken();
            // Relancer la requête
            return handler.resolve(
              await _dio.request(e.requestOptions.path)
            );
          }
          return handler.next(e);
        },
      ),
    );
  }
  
  Future<dynamic> get(String path) => _dio.get(path);
  Future<dynamic> post(String path, {data}) => _dio.post(path, data: data);
  Future<dynamic> put(String path, {data}) => _dio.put(path, data: data);
  Future<dynamic> delete(String path) => _dio.delete(path);
}
```

#### 4. **State Management**
Généralement: `StateNotifier` avec `flutter_riverpod` ou simple `ChangeNotifier`.

```dart
// Exemple avec ChangeNotifier
class AuthNotifier extends ChangeNotifier {
  final IAuthRepository _authRepo;
  
  UserEntity? _currentUser;
  UserEntity? get currentUser => _currentUser;
  
  AuthNotifier(this._authRepo);
  
  Future<void> login(String email, String password) async {
    try {
      final user = await _authRepo.login(email, password);
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
```

#### 5. **Firebase Integration**
- **FCM:** Notifications push
- **Local Notifications:** Affichage des notifications
- **Configuration:** `firebase_options.dart` (généré par FlutterFire CLI)

```dart
// core/notification_service.dart
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
    FlutterLocalNotificationsPlugin();
  
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  Future<void> init() async {
    // Demander permission
    await _firebaseMessaging.requestPermission();
    
    // Écouter les messages entrants
    FirebaseMessaging.onMessage.listen(_handleMessage);
  }
  
  void _handleMessage(RemoteMessage message) {
    // Afficher notification locale
    _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
    );
  }
}
```

#### 6. **SignalR for Real-time Updates**
WebSocket connection pour les mises à jour en temps réel.

```dart
// core/signalr_service.dart
class SignalRService {
  late HubConnection _hubConnection;
  
  Future<void> connect() async {
    final token = await _getAccessToken();
    _hubConnection = HubConnectionBuilder()
      .withUrl(
        AppConfig.apiUrl + "/hubs/reservation",
        HttpConnectionOptions(
          accessTokenFactory: () => Future.value(token),
        ),
      )
      .withAutomaticReconnect()
      .build();
    
    // Écouter les événements
    _hubConnection.on('ReceiveReservationUpdate', (arguments) {
      // Traiter la mise à jour
    });
    
    await _hubConnection.start();
  }
  
  Future<void> disconnect() => _hubConnection.stop();
}
```

---

## 📝 Conventions de Code

### Nommage de Fichiers

#### Écrans & Widgets
```dart
// snake_case avec suffixe descriptif
lib/features/auth/presentation/
├── login/
│   └── login_screen.dart          // Widget principal (Screen)
├── registration_tunnel/
│   └── step/
│       ├── step1_user_info_screen.dart
│       ├── step2_password_screen.dart
│       ├── step3_account_type_screen.dart
│       ├── step4_restaurant_info_screen.dart
│       ├── step5_table_management_screen.dart
│       └── step6_success_screen.dart
```

#### Repositories & Data
```dart
lib/features/user/
├── domain/
│   └── repositories/
│       └── user_repository.dart    # Interface IUserRepository
├── data/
│   ├── repositories/
│   │   └── user_repository_impl.dart  # Implémentation
│   ├── datasources/
│   │   ├── user_remote_datasource.dart
│   │   └── user_local_datasource.dart
│   └── models/
│       └── user_model.dart
```

### Nommage des Classes

```dart
// Screens
class LoginScreen extends StatefulWidget { }
class _LoginScreenState extends State<LoginScreen> { }

// Repositories (interfaces)
abstract class IUserRepository { }

// Repositories (implémentations)
class UserRepositoryImpl implements IUserRepository { }

// DataSources
class UserRemoteDataSource { }
class UserLocalDataSource { }

// Models/DTOs
class UserModel { }
class UserEntity { }

// Widgets réutilisables
class CustomButton extends StatelessWidget { }
class UserListItem extends StatelessWidget { }

// Services
class AuthService { }
class GeolocationService { }
```

### Propriétés & Variables

```dart
// Propriétés: camelCase
class User {
  final String email;
  final String firstName;
  final String lastName;
  final int accountType;
  final DateTime createdAt;
}

// Variables locales: camelCase
void loginUser() {
  final userId = 123;
  final userEmail = "user@example.com";
  var isAuthenticated = false;
}

// Constants: UPPER_SNAKE_CASE
const String API_BASE_URL = "https://api.tablemaster.com";
const Duration REQUEST_TIMEOUT = Duration(seconds: 10);
const int MAX_RETRY_COUNT = 3;

// Private: _leadingUnderscore
class _LoginScreenState extends State<LoginScreen> {
  final String _password;
  String _errorMessage = "";
}
```

### Async/Await Pattern

```dart
// Toutes les opérations réseau/storage sont async
Future<UserEntity?> getUserById(int id) async {
  try {
    final response = await _apiClient.get('/user/$id');
    return UserMapper.toEntity(response);
  } on DioException catch (e) {
    throw ApiException(e.message);
  }
}

// Appel async
void _loadUser() async {
  try {
    final user = await userRepository.getUserById(123);
    setState(() {
      _currentUser = user;
    });
  } catch (e) {
    _showError('Erreur: ${e.toString()}');
  }
}
```

### Error Handling

```dart
// Custom exception
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => message;
}

// Try-catch avec distinctions
try {
  final user = await _apiClient.get('/user/$id');
} on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    print('Timeout: La connexion a expiré');
  } else if (e.response?.statusCode == 401) {
    print('Unauthorized: Token invalide');
  } else {
    print('Erreur réseau: ${e.message}');
  }
} on ApiException catch (e) {
  print('API Error: ${e.message}');
} catch (e) {
  print('Erreur non gérée: $e');
}
```

### Localization (i18n)

```dart
// Toujours utiliser des clés i18n, pas du texte brut
// ❌ Mauvais
Text('Connexion'),

// ✅ Correct
Text(AppLocalizations.of(context)?.login ?? 'Login'),
// ou avec clés en dur pour le français:
Text('Connexion'),  // Car défaut est français
```

### Comments & Documentation

```dart
/// Documentation de classe (commentaire multilignes doc)
/// Utilisé pour la génération de docs.
class LoginScreen extends StatefulWidget {
  /// Explication détaillée d'une variable publique
  final String username;
  
  /// Comment du constructeur (après les paramètres)
  /// explique le but
  const LoginScreen({required this.username});
}

// Commentaires inline pour la logique complexe
void _complexLogic() {
  // Récupérer le token du stockage sécurisé
  final token = _getToken();
  
  // Vérifier l'expiration (comparaison avec DateTime.now())
  if (_isTokenExpired(token)) {
    // Relancer un refresh token
    _refreshToken();
  }
}
```

---

## 📂 Structure des Dossiers

```
lib/
│
├── core/                          # Infrastructure partagée
│   ├── api_client.dart           # Client HTTP (Dio)
│   ├── app_config.dart           # Configuration (URLs, secrets)
│   ├── app_constant.dart         # Constantes globales
│   ├── injection.dart            # GetIt setup (DI)
│   ├── localisation.dart         # i18n setup
│   ├── notification_service.dart # FCM + Local Notifications
│   ├── signalr_service.dart      # WebSocket SignalR
│   └── widgets/                  # Composants réutilisables
│       ├── custom_button.dart
│       ├── custom_text_field.dart
│       └── loading_indicator.dart
│
├── features/                      # Domaines métier (Clean Architecture)
│   ├── auth/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart        # abstract class IAuthRepository
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart   # implements IAuthRepository
│   │   └── presentation/
│   │       ├── login/
│   │       │   └── login_screen.dart
│   │       ├── registration_tunnel/
│   │       │   ├── registration_screen.dart    # Contrôleur principal
│   │       │   └── step/
│   │       │       ├── step1_user_info_screen.dart
│   │       │       ├── step2_password_screen.dart
│   │       │       ├── step3_account_type_screen.dart
│   │       │       ├── step4_restaurant_info_screen.dart
│   │       │       ├── step5_table_management_screen.dart
│   │       │       └── step6_success_screen.dart
│   │       └── widgets/
│   │           └── auth_form_widget.dart
│   │
│   ├── restaurant/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── restaurant_entity.dart
│   │   │   └── repositories/
│   │   │       └── restaurant_repository.dart
│   │   ├── data/
│   │   │   └── repositories/
│   │   │       └── restaurant_repository_impl.dart
│   │   └── presentation/
│   │       ├── restaurant_list_screen.dart
│   │       ├── restaurant_detail_screen.dart
│   │       └── restaurant_map_screen.dart
│   │
│   ├── reservation/
│   │   ├── domain/
│   │   ├── data/
│   │   └── presentation/
│   │       ├── reservation_list_screen.dart
│   │       ├── reservation_form_screen.dart
│   │       └── reservation_detail_screen.dart
│   │
│   ├── menu/
│   ├── table/
│   ├── review/
│   ├── daily_activity/
│   ├── closed_day_exception/
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart              # Écran d'accueil
│   └── user/
│       ├── domain/
│       ├── data/
│       └── presentation/
│           └── profile_screen.dart
│
├── main.dart                      # Entry point
├── firebase_options.dart          # Firebase config (généré)
├── splash_screen.dart             # Écran de démarrage
└── config/                        # Fichiers config par env
    ├── dev.json
    ├── android-emulate-dev.json
    └── prod.json

android/                          # Code natif Android
ios/                              # Code natif iOS
web/                              # Build web
windows/                          # Build desktop
linux/                            # Build desktop
macos/                            # Build macOS

pubspec.yaml                      # Dépendances
pubspec.lock                      # Lock file
analysis_options.yaml             # Linting rules
firebase.json                     # Firebase CLI config
devtools_options.yaml             # DevTools config
```

---

## 📢 Instructions de Réponse

### Langue & Tone
- **Toujours répondre en français** (technique et concis)
- **Tone:** Professionnel, direct, ergonomique
- **Exemples de code:** En Dart avec commentaires français

### Format de Réponse

#### Pour les bugs/erreurs
```
❌ **Problème:** Description concise du bug
🔍 **Cause:** Analyse rapide de la racine
✅ **Solution:** Code Dart corrigé
📝 **Explication:** 2-3 lignes max
```

#### Pour les nouvelles fonctionnalités
```
🎯 **Objectif:** Décrire la feature
📊 **Architecture:** Quelles couches impacter (Domain/Data/Presentation)
💻 **Implémentation:** Code minimal requis
✔️ **Tests:** Si applicable, tests unitaires avec mockito
```

#### Pour les questions d'architecture
```
🏗️ **Pattern recommandé:** Justifier le choix
📋 **Étapes:** Lister clairement
⚠️ **Pièges:** Avertissements pertinents
🔗 **Références:** Liens/exemples du projet
```

### Ordre de Priorité
1. **Interfaces first** → Déclarer l'interface avant l'implémentation
2. **Repository Pattern** → Toute source de données passe par un repository
3. **Injection GetIt** → Enregistrer dans `injection.dart`
4. **Error Handling** → Try-catch approprié avec DioException
5. **Localization** → Pas de strings brutes en dur

---

## 🔑 Composants Clés

### ApiClient
**Responsabilités:**
- Requêtes HTTP (GET, POST, PUT, DELETE)
- Gestion automatique du token d'accès
- Refresh automatique du token (401)
- Logging des requêtes

```dart
// Utilisation
final apiClient = getIt<ApiClient>();
final response = await apiClient.get('/restaurant/123');
```

### NotificationService
**Responsabilités:**
- Initialisation FCM
- Affichage des notifications locales
- Gestion des permissions

```dart
// Initialisation (dans main.dart)
await getIt<NotificationService>().init();

// Écoute des messages entrants (automatique après init)
```

### SignalRService
**Responsabilités:**
- Connexion WebSocket au serveur
- Reconnexion automatique
- Écoute des événements serveur

```dart
// Démarrer la connexion
await getIt<SignalRService>().connect();

// Écouter les événements
signalRService.on('ReservationStatusChanged', (data) {
  // Mettre à jour l'UI
});
```

### GetIt Service Locator
**Responsabilités:**
- Gestion des dépendances (DI)
- Instanciation singleton/lazy
- Résolution des dépendances circulaires

```dart
// Configuration (core/injection.dart)
void setupDependencies() {
  getIt.registerSingleton(ApiClient());
  getIt.registerSingleton<IAuthRepository>(AuthRepositoryImpl(getIt()));
}

// Utilisation
final authRepo = getIt<IAuthRepository>();
```

### FlutterSecureStorage
**Responsabilités:**
- Stockage sécurisé des tokens
- Chiffrement des données sensibles
- Stockage par clé/valeur

```dart
// Sauvegarder le token après login
const storage = FlutterSecureStorage();
await storage.write(key: 'access_token', value: token);
await storage.write(key: 'refresh_token', value: refreshToken);

// Récupérer le token
final token = await storage.read(key: 'access_token');

// Supprimer après logout
await storage.delete(key: 'access_token');
```

---

## 🌐 API Client & HTTP

### Requêtes Basiques

```dart
// GET
final response = await apiClient.get('/user/123');

// POST
final response = await apiClient.post(
  '/restaurant',
  data: {'name': 'Mon Restaurant', 'city': 'Paris'},
);

// PUT
final response = await apiClient.put(
  '/restaurant/123',
  data: {'name': 'Nouveau nom'},
);

// DELETE
await apiClient.delete('/restaurant/123');
```

### Gestion des Erreurs HTTP

```dart
try {
  final response = await apiClient.get('/user/123');
} on DioException catch (e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
      print('Timeout: Vérifiez votre connexion');
    case DioExceptionType.receiveTimeout:
      print('Timeout: Le serveur met trop de temps');
    case DioExceptionType.badResponse:
      if (e.response?.statusCode == 401) {
        print('Non autorisé: Token expiré');
      } else if (e.response?.statusCode == 403) {
        print('Accès refusé');
      }
    case DioExceptionType.cancel:
      print('Requête annulée par l\'utilisateur');
    default:
      print('Erreur réseau: ${e.message}');
  }
} catch (e) {
  print('Erreur non gérée: $e');
}
```

### Configuration Firebase

```bash
# Générer la config Firebase (exécuter une fois)
flutterfire configure

# Sélectionner:
# - Projet Firebase
# - Plateformes: android, ios, web

# Le fichier lib/firebase_options.dart est généré automatiquement
```

### Environnements

```bash
# Développement (API locale/test)
flutter run --dart-define-from-file=config/dev.json

# Émulateur Android (IP spéciale 10.0.2.2)
flutter run --dart-define-from-file=config/android-emulate-dev.json

# Production
flutter run --dart-define-from-file=config/prod.json
```

### Config File Structure

```json
// config/dev.json
{
  "apiUrl": "http://localhost:5000",
  "firebaseProjectId": "tablemaster-dev",
  "logNetworkRequests": true
}

// config/prod.json
{
  "apiUrl": "https://api.tablemaster.com",
  "firebaseProjectId": "tablemaster-prod",
  "logNetworkRequests": false
}
```

---

## ⚠️ Pièges Courants à Éviter

1. **❌ Importer directement une implémentation** → Toujours utiliser l'interface
2. **❌ Oublier `await`** → Toutes les opérations async doivent être attendues
3. **❌ Stocker des tokens en clair** → Toujours utiliser `FlutterSecureStorage`
4. **❌ Faire des requêtes HTTP dans Widgets** → Utiliser les repositories
5. **❌ Mélanger les couches** → Présentation n'accède pas à la Data Layer directement
6. **❌ Ne pas gérer les erreurs** → Toujours try-catch les opérations réseau
7. **❌ Hardcoder les URLs** → Toujours utiliser `AppConfig`
8. **❌ Naviguer sans arguments** → Passer les données via constructeur ou Named Routes

---

## 🚀 Build & Déploiement

### Build APK (Android)
```bash
flutter build apk --release --dart-define-from-file=config/prod.json
# Sortie: build/app/outputs/flutter-apk/app-release.apk
```

### Build AAB (Google Play)
```bash
flutter build appbundle --release --dart-define-from-file=config/prod.json
```

### Build iOS
```bash
flutter build ios --release --dart-define-from-file=config/prod.json
```

### Build Web
```bash
flutter build web --release --dart-define-from-file=config/prod.json
```

---

## 📞 Ressources

- **Documentation Flutter:** https://flutter.dev
- **Dart Docs:** https://dart.dev
- **Firebase Flutter:** https://firebase.flutter.dev
- **Dio Package:** https://pub.dev/packages/dio
- **Get It:** https://pub.dev/packages/get_it
- **SignalR Client:** https://pub.dev/packages/signalr_netcore

---

**Generated for GitHub Copilot** | Mis à jour régulièrement
