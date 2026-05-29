# TableMasterMobile - Instructions Agent

Ces instructions s'appliquent au projet `TableMasterMobile/`. Repondre a l'utilisateur en francais.

## Projet

- Application Flutter/Dart, SDK Dart `^3.7.0`.
- UI mobile et web Flutter pour TableMaster.
- Client HTTP centralise : `lib/core/api_client.dart` avec Dio.
- Injection de dependances : GetIt dans `lib/core/injection.dart`.
- Stockage securise : `flutter_secure_storage`.
- Notifications : Firebase Messaging et notifications locales.
- Temps reel : `signalr_netcore`.
- Cartes/localisation : Google Maps et Geolocator.
- Monitoring : Sentry Flutter (`sentry_flutter`).
- Lint : `analysis_options.yaml` avec `flutter_lints`.

## Commandes

Executer depuis ce dossier :

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define-from-file=config/dev.json
flutter run --dart-define-from-file=config/devEmulator.json
flutter build apk --dart-define-from-file=config/prod.json
flutter build appbundle --dart-define-from-file=config/prod.json
```

Utiliser `config/devEmulator.json` pour l'emulateur Android et `config/dev.json` pour le developpement local classique.
Pour activer Sentry localement, ajouter `--dart-define=SENTRY_DSN=<dsn-flutter>` ; pour le test debug de demarrage, ajouter aussi `--dart-define=SENTRY_ENABLE_STARTUP_TEST_EVENT=true`.

## Architecture

- `lib/core/` : infrastructure commune, configuration, API, DI, navigation, localisation, notifications, SignalR, erreurs et widgets partages.
- `lib/features/<feature>/domain/repositories/` : interfaces de repositories.
- `lib/features/<feature>/data/datasources/` : appels API et stockage local eventuel.
- `lib/features/<feature>/data/models/` : DTO et modeles de transport.
- `lib/features/<feature>/data/repositories/` : implementations des repositories.
- `lib/features/<feature>/presentation/` : pages, ecrans, widgets et controllers de presentation.

Respecter le style Clean Architecture existant : la presentation appelle les repositories, les repositories appellent les datasources, les datasources utilisent `ApiClient`.

## API et Auth

- Base API : `AppConfig.apiUrl + "/api"`.
- Header de version : `x-api-version: 1.0`.
- Cle du token d'acces : `access_token`.
- Cle du refresh token : `refresh_token`.
- Sentry Flutter est initialise dans `lib/main.dart` seulement si `AppConfig.sentryDsn` est fourni via `SENTRY_DSN`.
- Ne pas dupliquer la logique de token, refresh ou headers hors de `ApiClient` et du repository auth.
- En cas de changement de route, modele, statut HTTP ou comportement auth cote API, mettre a jour le datasource, le modele et le repository correspondants.

## Injection

- Enregistrer les nouveaux datasources et repositories dans `lib/core/injection.dart`.
- Reutiliser le singleton `ApiClient` pour conserver les headers, l'authentification et le refresh centralises.
- Ajouter les dependances dans le meme ordre logique que les features existantes.
- Eviter les clients Dio independants, sauf cas tres localise et justifie.

## Conventions Dart/Flutter

- Fichiers en `snake_case.dart`.
- Classes et widgets en PascalCase.
- Variables, parametres et methodes en camelCase.
- Membres prives avec `_`.
- Textes d'interface en francais, sauf si l'ecran suit deja une autre convention.
- Gerer explicitement les `DioException` quand le code touche aux appels API.
- Garder les widgets lisibles : extraire un widget quand une page devient difficile a parcourir, sans sur-abstraire.
- Preserver les assets declares dans `pubspec.yaml` et eviter les chemins codifies en dur si un helper ou une constante existe.

## Tests

- Lancer `flutter analyze` avant de terminer si possible.
- Lancer `flutter test` pour les changements de logique, repositories, auth, API ou widgets.
- Garder les tests deterministes, sans vrai appel reseau.
- Preferer des tests cibles autour du comportement modifie plutot qu'une grande suite fragile.

## Securite

- Ne pas afficher ni commiter les configs Firebase privees, cles de signature, secrets API ou chemins locaux sensibles.
- Ne pas afficher ni commiter le DSN Sentry reel ; utiliser `--dart-define=SENTRY_DSN=...` en local et le secret GitHub Actions `SENTRY_DSN_FLUTTER` en CI.
- Eviter les dossiers generes : `build/`, `.dart_tool/`, `.gradle/`, fichiers plugins generes et metadonnees IDE.
- Ne pas modifier les fichiers de plateforme Android/iOS generes sauf besoin explicite.
