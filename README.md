# table_master_mobile

A new Flutter project.

# 📁 Documentation du Projet Flutter

Ce projet utilise un système de configurations par environnement (**Dev** & **Prod**) via des fichiers JSON.  
Cela permet de séparer les URLs d'API et les clés secrètes.

---

## ⚙️ Configuration des Environnements

Les fichiers de configuration se trouvent dans le dossier `config/` :

- `config/dev.json` : Utilisé pour le développement local et les tests
- `config/prod.json` : Utilisé pour la version finale destinée aux utilisateurs

> ⚠️ **Note**  
> Si vous ajoutez des clés sensibles, assurez-vous que ce dossier est listé dans votre `.gitignore`.

---

## 🚀 Commandes de Lancement

### 🛠 Environnement de Développement (Debug)

Pour lancer l'application en mode debug avec l'API de développement :

```bash
flutter run --dart-define-from-file=config/dev.json
```
### 🌍 Environnement de Production (Release)
Pour tester les performances réelles avec l'API de production sur un appareil :

```bash
flutter run --release --dart-define-from-file=config/prod.json
```
## 📦 Commandes de Build (Génération des exécutables)
Utilisez ces commandes pour générer les fichiers à distribuer (APK ou AppBundle).

### 🤖 Android
Build pour le Développement (APK de test)
```bash
flutter build apk --debug --dart-define-from-file=config/dev.json
```
### Build pour la Production (Google Play Store)
```bash
flutter build appbundle --dart-define-from-file=config/prod.json
```

## 🍎 iOS
### Build pour le Développement :

```Bash
flutter build ios --debug --dart-define-from-file=config/dev.json
```
### Build pour la Production (App Store Connect) :

```Bash
flutter build ipa --dart-define-from-file=config/prod.json
```