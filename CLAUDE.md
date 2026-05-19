# TableMasterMobile — Contexte Claude Code

Répondre en français. Limiter les changements strictement à la demande.

## Vue d'ensemble

Application **Flutter / Dart** (mobile + web) cliente de l'API TableMaster. Suit un découpage **Clean Architecture par feature**.

- **SDK** : Dart `^3.7.0`, Flutter (lints `flutter_lints ^5`).
- **HTTP** : `dio ^5` via un **client centralisé** `lib/core/api_client.dart` (gère headers, auth, refresh).
- **DI** : `get_it ^9` dans `lib/core/injection.dart`.
- **Stockage sécurisé** : `flutter_secure_storage` (tokens).
- **Temps réel** : `signalr_netcore`.
- **Notifications** : `firebase_messaging` + `flutter_local_notifications`.
- **Cartes / géoloc** : `google_maps_flutter`, `geolocator`.
- **Divers** : `confetti`, `audioplayers`, `url_launcher`, `intl`.

## Structure du repo

```
lib/
├── main.dart                      bootstrap
├── splash_screen.dart
├── firebase_options.dart          généré par flutterfire configure
├── core/                          infra commune
│   ├── api_client.dart            Dio centralisé (singleton)
│   ├── app_config.dart            config par environnement (dart-define)
│   ├── app_constant.dart
│   ├── injection.dart             enregistrements GetIt
│   ├── localisation.dart
│   ├── navigation/
│   ├── notification_service.dart
│   ├── signalr_service.dart
│   ├── session/
│   ├── errors/
│   ├── logging/
│   └── widgets/                   widgets partagés
└── features/                      découpé par domaine
    ├── auth/
    ├── closed_day_exception/
    ├── daily_activity/
    ├── home/
    ├── menu/
    ├── reservation/
    ├── restaurant/
    ├── review/
    ├── room/
    ├── table/
    └── user/
config/                            configs d'environnement (--dart-define-from-file)
├── dev.json
├── android-emulate-dev.json       pour émulateur Android (10.0.2.2)
└── prod.json
android/  ios/  web/  windows/  macos/  linux/   plateformes Flutter
```

Chaque feature suit :

```
features/<feature>/
├── domain/repositories/           interfaces
├── data/
│   ├── datasources/               appels API / stockage local
│   ├── models/                    DTO de transport
│   └── repositories/              implémentations
└── presentation/                  pages, écrans, widgets, controllers UI
```

Flux : **presentation → repositories → datasources → `ApiClient`**.

## Commandes

```bash
flutter pub get
flutter analyze
flutter test

# Dev
flutter run --dart-define-from-file=config/dev.json
flutter run --dart-define-from-file=config/android-emulate-dev.json   # émulateur Android

# Prod
flutter run --release --dart-define-from-file=config/prod.json
flutter build apk        --dart-define-from-file=config/prod.json
flutter build appbundle  --dart-define-from-file=config/prod.json
flutter build ipa        --dart-define-from-file=config/prod.json

# Firebase (regen lib/firebase_options.dart)
flutterfire configure
```

## API & auth

- Base API : `AppConfig.apiUrl + "/api"`.
- Header version : `x-api-version: 1.0`.
- Clés tokens : `access_token`, `refresh_token` (secure storage).
- **Toute** la logique token / refresh / headers reste dans `ApiClient` + repository auth — ne pas dupliquer.
- Si l'API change (route, modèle, statut HTTP, comportement auth) → mettre à jour datasource + modèle + repository concernés.

## Ajouter une feature

1. Créer `features/<feature>/{domain,data,presentation}/`.
2. Définir l'interface repository (domain) + l'implémentation + datasource + models (data).
3. Enregistrer datasource + repository dans `lib/core/injection.dart` (même ordre que l'existant).
4. Réutiliser le singleton `ApiClient` — **pas** de Dio indépendant sauf cas justifié.
5. UI dans `presentation/`, extraire un widget quand la page devient lourde.

## Conventions Dart/Flutter

- Fichiers `snake_case.dart`.
- Classes / widgets PascalCase, méthodes/vars camelCase, prefix `_` pour le privé.
- **Textes UI en français**, sauf écran déjà conventionné autrement.
- Gérer explicitement les `DioException` sur tout appel API.
- Préserver les assets déclarés dans `pubspec.yaml` (logo, sons) — pas de chemins en dur si une constante existe.

## Tests

- `flutter analyze` avant de finir si possible.
- `flutter test` sur changements de logique, repositories, auth, API, widgets.
- Tests déterministes, **pas d'appel réseau réel**.

## Sécurité

- **Ne pas commiter** : configs Firebase privées, clés de signature, secrets API, chemins locaux sensibles.
- Ignorer `build/`, `.dart_tool/`, `.gradle/`, plugins générés, métadonnées IDE.
- Ne pas modifier les fichiers de plateforme Android/iOS générés sauf besoin explicite.

## Voir aussi

- `AGENTS.md`, `README.md`, `CI_CD.md`.
