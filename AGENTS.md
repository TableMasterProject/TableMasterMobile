# TableMasterMobile Agent Instructions

These instructions apply to `TableMasterMobile/`.

## Project

- Flutter/Dart app with SDK constraint `^3.7.0`.
- HTTP client: Dio through `lib/core/api_client.dart`.
- Dependency injection: GetIt through `lib/core/injection.dart`.
- Secure storage: `flutter_secure_storage`.
- Notifications: Firebase Messaging and local notifications.
- Realtime: `signalr_netcore`.
- Maps/location: Google Maps and Geolocator.
- Linting: `analysis_options.yaml` and `flutter_lints`.

Answer the user in French and keep changes aligned with the existing app structure.

## Commands

Run from this directory:

```bash
flutter pub get
flutter analyze
flutter test
flutter run --dart-define-from-file=config/dev.json
flutter run --dart-define-from-file=config/android-emulate-dev.json
flutter build apk --dart-define-from-file=config/prod.json
flutter build appbundle --dart-define-from-file=config/prod.json
```

Use `config/android-emulate-dev.json` for Android emulator API access and `config/dev.json` for normal local development.

## Architecture

- `lib/core/`: shared infrastructure such as API client, config, DI, localization, notifications, and SignalR.
- `lib/features/<feature>/domain/repositories/`: repository interfaces.
- `lib/features/<feature>/data/datasources/`: remote/local data sources.
- `lib/features/<feature>/data/models/`: DTOs/models.
- `lib/features/<feature>/data/repositories/`: repository implementations.
- `lib/features/<feature>/presentation/`: screens, pages, and widgets.

Follow the existing Clean Architecture style. Presentation calls repositories; repositories call datasources; datasources use `ApiClient`.

## Dependency Injection

- Register new datasources and repositories in `lib/core/injection.dart`.
- Reuse the singleton `ApiClient` so auth headers and token refresh stay centralized.
- Do not create independent Dio clients except for tightly scoped cases like the existing refresh-token retry flow.

## Dart Conventions

- Use snake_case file names.
- Use PascalCase for classes and widgets.
- Use camelCase for variables, parameters, and methods.
- Use a leading underscore for private members.
- Keep UI text in French unless the surrounding screen already uses another convention.
- Prefer explicit error handling for `DioException`.
- Do not duplicate token storage or refresh logic outside `ApiClient` and auth repository code.

## API Contract

- Base API path is `AppConfig.apiUrl + "/api"`.
- API version header is `x-api-version: 1.0`.
- Access token storage key: `access_token`.
- Refresh token storage key: `refresh_token`.
- If an API model, route, status code, or auth behavior changes, update the matching datasource/model/repository in this app.

## Testing

- Run `flutter analyze` before finishing mobile changes when feasible.
- Run `flutter test` for logic, repository, auth, API integration, and widget changes.
- Keep tests deterministic and avoid real network calls.

## Safety

- Do not commit or display Firebase private config, signing credentials, API secrets, or local machine paths from generated config.
- Avoid editing generated/build directories: `build/`, `.dart_tool/`, `.gradle/`, platform generated plugin files, and IDE metadata.
