# 📁 TableMaster Mobile - Guide de configuration

Ce projet est une application Flutter utilisant Firebase pour les notifications et un système de configuration par environnement.

---

## 🔥 Configuration Firebase

Pour lier l'application à Firebase (ou mettre à jour la configuration), suivez ces étapes :

### 1. Prérequis
Assurez-vous d'avoir installé le **Firebase CLI** et d'être connecté :
```bash
npm install -g firebase-tools
firebase login
```

### 2. Installation de FlutterFire CLI
Si ce n'est pas déjà fait, installez l'outil de configuration FlutterFire :
```bash
dart pub global activate flutterfire_cli
```
*Note : Assurez-vous que le chemin des exécutables Dart est dans votre PATH.*

### 3. Commande de Liaison (Lien Firebase)
Pour générer ou mettre à jour le fichier `lib/firebase_options.dart` :
```bash
flutterfire configure
```
Sélectionnez votre projet Firebase et les plateformes souhaitées (android, ios, web).

---

## ⚙️ Configuration des Environnements

L'application utilise des fichiers JSON dans le dossier `config/` pour gérer les variables selon l'environnement :

- `config/dev.json` : Développement local / API de test.
- `config/devEmulator.json` : Spécifique pour l'émulateur Android (pointe souvent vers 10.0.2.2).
- `config/prod.json` : Configuration de production.

Sentry est activé uniquement si un DSN est fourni au build/run via `--dart-define=SENTRY_DSN=...`. Les fichiers `config/*.json` ne contiennent pas le DSN.

---

## 🚀 Commandes de Lancement

### 🛠 Développement (Debug)
```bash
# Avec config dev standard
flutter run --dart-define-from-file=config/dev.json

# Pour l'émulateur Android
flutter run --dart-define-from-file=config/devEmulator.json

# Debug avec Sentry activé
flutter run --dart-define-from-file=config/devEmulator.json \
  --dart-define=SENTRY_DSN=<dsn-flutter>

# Envoyer un message de test Sentry au démarrage (debug uniquement)
flutter run --dart-define-from-file=config/devEmulator.json \
  --dart-define=SENTRY_DSN=<dsn-flutter> \
  --dart-define=SENTRY_ENABLE_STARTUP_TEST_EVENT=true
```

### 🌍 Production
```bash
flutter run --release --dart-define-from-file=config/prod.json \
  --dart-define=SENTRY_DSN=<dsn-flutter>
```

---

## 📦 Génération des builds (Release)

### 🤖 Android
```bash
# Générer l'APK
flutter build apk --dart-define-from-file=config/prod.json \
  --dart-define=SENTRY_DSN=<dsn-flutter>

# Générer l'App Bundle (Play Store)
flutter build appbundle --dart-define-from-file=config/prod.json \
  --dart-define=SENTRY_DSN=<dsn-flutter>
```

### 🍎 iOS
```bash
flutter build ipa --dart-define-from-file=config/prod.json \
  --dart-define=SENTRY_DSN=<dsn-flutter>
```

---

## 🛠 Maintenance du projet

- **Nettoyage :** `flutter clean`
- **Récupérer les dépendances :** `flutter pub get`
