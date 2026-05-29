# Sécurité — TableMasterMobile

> Document de référence Bloc 2 — C2.2.3 du RNCP39583.
> Mapping des mesures de sécurité **côté application Flutter** face à l'**OWASP Mobile Top 10 (2024)** et aux principes OWASP web applicables.

## Synthèse

| Risque | Couverture | Localisation |
| --- | :---: | --- |
| M1/A01 Mauvaise authentification et autorisation | ✅ | `ApiClient` + repository auth |
| M2/A02 Stockage des données peu sûr | ✅ | `flutter_secure_storage` pour tokens |
| M3 Communication non sécurisée | ✅ | HTTPS forcé via `AppConfig.apiUrl` |
| M4 Mauvaise gestion d'identifiants | ✅ | Tokens hors code, scopés par device |
| M5 Cryptographie faible | ✅ | Pas de crypto maison ; FCM/SignalR géré |
| M6 Code privilégié non protégé | ✅ | Configuration via `--dart-define` |
| M7 Mauvaise qualité du code client | ⚠️ | Lints + tests à étoffer (couverture en cours) |
| M8 Falsification de code | ⚠️ | Signature stores OK, root/jailbreak detection N/A |
| M9 Reverse engineering | ⚠️ | Obfuscation Dart à activer en release |
| M10 Fonctionnalité superflue | ✅ | Pas d'API debug exposée en release |

---

## M1 / A01 — Authentification & autorisation

**Risque** : un token volé ouvre l'accès au compte ; une mauvaise vérification côté serveur autorise des accès non prévus.

**Mesures :**
- L'authentification est centralisée dans `lib/features/auth/` — un seul flow `login` / `refresh` / `logout`.
- Le `ApiClient` (`lib/core/api_client.dart`) attache automatiquement le `Authorization: Bearer <access_token>` à chaque requête.
- Lorsqu'un `401` est reçu, `ApiClient` déclenche le refresh via `IAuthRepository.refresh` → un seul refresh concurrent, file d'attente des requêtes en cours.
- L'autorisation **fine** reste de la responsabilité de l'API (cf. `TableMasterApi/SECURITY.md`). L'app n'expose jamais d'écran "admin" basé uniquement sur un drapeau local.

## M2 / A02 — Stockage local sécurisé

**Risque** : tokens ou données sensibles accessibles à un attaquant en cas de root/jailbreak ou backup.

**Mesures :**
- Tous les jetons (`access_token`, `refresh_token`, `user_id`, `fcm_token`) stockés via **`flutter_secure_storage`** — Keychain iOS / EncryptedSharedPreferences Android.
- **Aucune** persistance des mots de passe ni des PII utilisateur.
- Au `logout`, la classe `AuthRepositoryImpl` purge explicitement toutes les clés sensibles avant de fermer la session.

## M3 — Communication réseau

**Risque** : MITM sur Wi-Fi public, sniffing.

**Mesures :**
- L'URL de l'API est définie via `--dart-define-from-file=config/{env}.json` et toujours en HTTPS pour `prod.json`.
- L'app n'autorise pas les certificats invalides (paramètres Dio par défaut).
- Le hub SignalR (`signalr_netcore`) hérite des mêmes garanties TLS.

## M4 — Gestion des identifiants

**Mesures :**
- Aucun secret API n'est embarqué dans l'app (clés Firebase publiques par nature).
- Les configs `config/*.json` ne contiennent **que** des URLs et des feature flags publics.
- Le DSN Sentry est injecté au build/run via `--dart-define=SENTRY_DSN=...` ou le secret CI `SENTRY_DSN_FLUTTER`, jamais écrit en dur.

## M5 — Cryptographie

**Mesures :**
- L'app ne fait **pas** de cryptographie maison.
- La crypto est déléguée à : OS pour le secure storage, OS pour TLS, Firebase pour FCM, .NET pour JWT (vérifié côté serveur, jamais côté client).

## M6 — Configuration

**Mesures :**
- Configuration injectée au build via `--dart-define-from-file` — aucune valeur sensible dans le code.
- Pas de "debug menu" dans le binaire `release`.
- Sentry Flutter est activé seulement si `SENTRY_DSN` est fourni ; `SENTRY_ENABLE_STARTUP_TEST_EVENT` sert uniquement au test local debug.

## M7 — Qualité du code client

**Mesures :**
- Lints `flutter_lints ^5.0.0` actifs (`analysis_options.yaml`).
- Tests unitaires sur les **repositories** des 4 features critiques (auth, reservation, restaurant, user) — voir `test/`.
- `flutter analyze` lancé en CI (`.github/workflows/flutter.yml`).

**À renforcer** : étendre la couverture aux 7 features restantes (cf. `test/README.md`).

## M8 — Falsification de code

**Mesures :**
- Build release Android signé par keystore privée (hors Git).
- Build iOS via Apple Developer Account (provisioning géré côté Xcode/Codemagic).

**Hors scope actuel** : root/jailbreak detection (justifié — app non bancaire, données restaurant à faible criticité).

## M9 — Reverse engineering

**État actuel** : pas d'obfuscation Dart activée.

**À activer pour release prod** :
```bash
flutter build apk --release --obfuscate --split-debug-info=build/symbols/
flutter build ipa --release --obfuscate --split-debug-info=build/symbols/
```

## M10 — Fonctionnalité superflue

**Mesures :**
- Aucun écran de debug exposé en mode release (vérifié via `kReleaseMode`).
- Logs `AppLogger` filtrés en release (niveau `info` minimum).
- Sentry collecte les erreurs applicatives et traces avec `sendDefaultPii=false`.
- Pas d'endpoint réseau additionnel atteint par l'app au-delà de l'API officielle et de Sentry.

---

## RGPD / Vie privée

- **Consentement** : à la première utilisation, l'utilisateur accepte les CGU et la politique de confidentialité.
- **Droit à l'effacement** : implémenté côté API (`UserRepositoryImpl.deleteAccount`) et exposé dans l'écran *Compte*.
- **Données collectées** : email, prénom, nom, téléphone (restaurateur), géoloc utilisée localement (jamais persistée).
- **Notifications** : token FCM stocké côté serveur, lié au user, supprimé au logout.

## À auditer périodiquement

| Quand | Action |
| --- | --- |
| À chaque PR | `flutter analyze` + `flutter test` (CI) |
| À chaque release | `flutter build` avec `--obfuscate` + vérifier la taille binaire |
| Trimestriel | `flutter pub outdated` + revue des plugins natifs |
| Annuel | Revue manuelle de ce document |
