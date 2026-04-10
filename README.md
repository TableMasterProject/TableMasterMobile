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
- `config/android-emulate-dev.json` : Spécifique pour l'émulateur Android (pointe souvent vers 10.0.2.2).
- `config/prod.json` : Configuration de production.

---

## 🚀 Commandes de Lancement

### 🛠 Développement (Debug)
```bash
# Avec config dev standard
flutter run --dart-define-from-file=config/dev.json

# Pour l'émulateur Android
flutter run --dart-define-from-file=config/android-emulate-dev.json
```

### 🌍 Production
```bash
flutter run --release --dart-define-from-file=config/prod.json
```

---

## 📦 Génération des builds (Release)

### 🤖 Android
```bash
# Générer l'APK
flutter build apk --dart-define-from-file=config/prod.json

# Générer l'App Bundle (Play Store)
flutter build appbundle --dart-define-from-file=config/prod.json
```

### 🍎 iOS
```bash
flutter build ipa --dart-define-from-file=config/prod.json
```

---

## 🛠 Maintenance du projet

- **Nettoyage :** `flutter clean`
- **Récupérer les dépendances :** `flutter pub get`
