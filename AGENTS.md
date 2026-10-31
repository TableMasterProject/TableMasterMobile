# TableMasterMobile - Instructions Agent

Ces instructions s'appliquent au projet `TableMasterMobile/`. Repondre a l'utilisateur en francais.

## Workflow Obligatoire

- Avant toute action, lire tous les `AGENTS.md` applicables, verifier `git status --short` et preserver les changements utilisateur existants.
- Identifier uniquement les skills directement utiles a la tache et lire leur `SKILL.md` avant d'agir. Ne pas charger de skills sans rapport avec la demande.
- Pour un bug non trivial, une regression ou une cause inconnue, utiliser `superpowers:systematic-debugging` avant toute correction. Une faute de frappe ou une correction evidente ne requiert pas ce workflow complet.
- Pour une fonctionnalite ou une correction de comportement testable, utiliser `superpowers:test-driven-development` et commencer par le plus petit test pertinent.
- Avant toute affirmation de reussite, utiliser `superpowers:verification-before-completion` avec la plus petite preuve fraiche couvrant reellement le changement.
- Quand `graphify-out/graph.json` existe, interroger Graphify avant l'exploration large. Utiliser ensuite `rg` pour rechercher le contenu et `fd` pour trouver les fichiers.
- Utiliser le skill `playwright-cli` pour les parcours Flutter Web, le responsive et les interactions navigateur concernes. Playwright ne remplace jamais les tests unitaires ou de widgets Flutter.
- Ne jamais commiter, pousser, publier, supprimer ou ecraser des fichiers sans demande explicite.

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

- Toute logique ajoutee ou modifiee doit avoir des tests Dart/Flutter cibles couvrant le cas nominal, les erreurs attendues et les regressions pertinentes.
- Pour un bug, le test de regression doit echouer avant la correction puis reussir apres celle-ci.
- Ajouter des tests de widgets pour les interactions, etats de chargement, erreurs et comportements visuels modifies.
- Garder les tests deterministes, sans vrai appel reseau.
- Preferer des tests cibles autour du comportement modifie plutot qu'une grande suite fragile.
- Executer d'abord les tests cibles et une analyse limitee aux fichiers ou au package concerne lorsque l'outil le permet.
- Executer `flutter analyze` et `flutter test` sur tout le projet seulement pour un changement transverse, l'authentification, l'API partagee, la navigation, l'injection, une release ou a la demande explicite de l'utilisateur.
- Pour un parcours Flutter Web modifie, lancer l'application Web avec la configuration adaptee et verifier le parcours concerne avec Playwright CLI. Verifier une largeur mobile et une largeur desktop si le responsive est touche.
- Pour une modification Android, iOS, Web ou de configuration de release, executer aussi le build cible pertinent lorsque l'environnement le permet.
- Executer `git diff --check` avant de conclure.
- Il est interdit d'annoncer que le travail est termine si une analyse, un test, un build requis ou une verification obligatoire echoue.
- Si l'environnement empeche reellement une verification, indiquer la commande tentee, l'erreur exacte et le perimetre restant non verifie. Ne jamais presenter ce cas comme une reussite.

## Securite

- Ne pas afficher ni commiter les configs Firebase privees, cles de signature, secrets API ou chemins locaux sensibles.
- Ne pas afficher ni commiter le DSN Sentry reel ; utiliser `--dart-define=SENTRY_DSN=...` en local et le secret GitHub Actions `SENTRY_DSN_FLUTTER` en CI.
- Eviter les dossiers generes : `build/`, `.dart_tool/`, `.gradle/`, fichiers plugins generes et metadonnees IDE.
- Ne pas modifier les fichiers de plateforme Android/iOS generes sauf besoin explicite.

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

When the user types `/graphify`, use the installed graphify skill or instructions before doing anything else.

Rules:
- When graphify-out/graph.json exists and the question is architectural, cross-file or has an unknown location, run `graphify query "<question>"` before broad search. For a known file, symbol or small local change, direct `rg`, `fd` and source reads are allowed. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts.
- Dirty graphify-out/ files are expected after hooks or incremental updates; dirty graph files are not a reason to skip graphify. Only skip graphify if the task is about stale or incorrect graph output, or the user explicitly says not to use it.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After structural or cross-file code changes, run `graphify update .` to keep the graph current. Skip it for documentation, configuration and small local text changes.
- A committed graphify-out/graph.json is rewritten whole on every build, so a large diff to it in a pull request is expected. Do not flag it as churn or suggest skipping the graph rebuild or its hooks.
