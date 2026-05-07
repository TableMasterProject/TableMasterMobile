# 🚀 CI/CD - TableMaster Mobile

## GitHub Actions Workflow

Ce repo utilise GitHub Actions pour compiler et builder l'app Flutter automatiquement.

### 📋 Workflow: `.github/workflows/flutter.yml`

**Déclenché:**
- ✅ Chaque `push` sur `main` ou `develop`
- ✅ Chaque `pull_request` vers `main` ou `develop`

**Actions exécutées:**
1. 🔧 Setup Flutter 3.38.9
2. 📦 Restaure les dépendances (`flutter pub get`)
3. 🔍 Analyse Dart (`flutter analyze`)
4. 📱 Build Web Release (63.5s)
5. 🤖 Build APK Release (205s, 58 MB)
6. 📦 Build AAB Release (Google Play)
7. 🐧 Build Linux Desktop
8. 💾 Upload tous les artefacts

**Durée:** ~5-7 minutes

---

## 📦 Artefacts

Après chaque run, les artefacts sont disponibles dans **Actions → [Run] → Artifacts:**

### `flutter-web-build/`
```
build/web/
├── index.html
├── main.dart.js
├── main.dart.js.map
└── assets/
    ├── fonts/
    ├── packages/
    └── ...
```

**Utilisation:**
```bash
# Servir localement:
python -m http.server --directory build/web/

# Déployer sur Netlify/Vercel:
netlify deploy --prod --dir build/web/
```

### `flutter-apk/`
```
build/app/outputs/flutter-apk/
└── app-release.apk (58.0 MB)
```

**Utilisation:**
- 📱 Installer sur Android: `adb install app-release.apk`
- 📤 Télécharger sur Firebase App Distribution
- 🏪 Beta testing avant Google Play

### `flutter-aab/`
```
build/app/outputs/bundle/release/
└── app-release.aab
```

**Utilisation:**
- 🏪 Upload direct sur Google Play Console
- ✅ Format recommandé par Google (plus petit, optimisé)

### `flutter-linux-build/`
```
build/linux/
└── release/
    └── bundle/
        ├── tablemaster_mobile
        └── lib/
```

**Utilisation:**
- 🐧 Desktop app pour Linux

---

## 🔍 View Logs

1. Aller à **Actions** sur GitHub
2. Cliquer sur le workflow **Flutter Build CI**
3. Cliquer sur le run
4. Voir les logs complets de chaque step

---

## 🛠️ Troubleshooting

### ❌ Workflow ne s'exécute pas

**Vérifier:**
- ✅ Workflow activé: **Actions → ... → Enable workflows**
- ✅ Branches `main` et `develop` existent
- ✅ Fichier `.github/workflows/flutter.yml` existe

### ❌ Flutter build échoue

**Relancer localement:**
```bash
flutter clean
flutter pub get
flutter build apk --release
```

**Vérifier les dépendances:**
```bash
flutter pub outdated
flutter pub upgrade
```

**Voir les erreurs détaillées:**
```bash
flutter build apk --release -v
```

### ❌ Build trop lent (timeout)

- Le build APK peut prendre 200+ secondes
- GitHub Actions timeout par défaut: 360 minutes (6h) - pas de problème
- Si vraiment trop lent, augmenter `timeout-minutes` dans le workflow

---

## 🚀 Déploiement

### Option 1: Firebase App Distribution (Beta Testing)

```yaml
- name: Deploy to Firebase
  uses: wzieba/Firebase-Distribution-Github-Action@v1
  if: success()
  with:
    serviceCredentialsFile: ./credentials.json
    file: build/app/outputs/flutter-apk/app-release.apk
    groups: testers
    releaseNotes: "Build ${{ github.run_number }}"
```

Ajouter `credentials.json` dans **Settings → Secrets → Actions**

### Option 2: Google Play Console (Production)

```yaml
- name: Deploy to Google Play
  uses: r0adkll/upload-google-play@v1
  if: success()
  with:
    serviceAccountJsonPlainText: ${{ secrets.GOOGLE_PLAY_KEY }}
    packageName: com.tablemaster.app
    releaseFiles: build/app/outputs/bundle/release/app-release.aab
    track: beta  # ou 'production' après tests
```

### Option 3: Netlify (Web App)

```yaml
- name: Deploy Web to Netlify
  uses: nwtgck/actions-netlify@v2.1
  if: success()
  with:
    publish-dir: build/web/
    production-branch: main
  env:
    NETLIFY_AUTH_TOKEN: ${{ secrets.NETLIFY_AUTH_TOKEN }}
    NETLIFY_SITE_ID: ${{ secrets.NETLIFY_SITE_ID }}
```

---

## 📊 Build Sizes

| Target | Size | Temps |
|--------|------|-------|
| Web | ~50 MB (total avec assets) | 63s |
| APK | 58 MB | 205s |
| AAB | ~45 MB | 200s |
| Linux | ~100 MB | 150s |

---

## 📱 Platforms Actuellement Buildés

✅ **Web** (HTML5/JavaScript)
✅ **Android** (APK + AAB)
✅ **Linux Desktop**

⚠️ **iOS** - Non buildé sur Linux (nécessite macOS)
⚠️ **Windows** - Non buildé (nécessite Windows)
⚠️ **macOS** - Non buildé (nécessite macOS)

Pour iOS/Windows/macOS, créer des workflows séparés sur macOS/Windows runners.

---

## 🔐 Secrets Nécessaires

Pour le déploiement automatique, ajouter à **Settings → Secrets and variables → Actions:**

```
GOOGLE_PLAY_KEY          # JSON file from Google Play Console
FIREBASE_CREDENTIALS     # Service account JSON
NETLIFY_AUTH_TOKEN       # Netlify personal access token
NETLIFY_SITE_ID          # Netlify site ID
```

---

## 📚 Ressources

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Flutter CI/CD Guide](https://flutter.dev/docs/deployment/cd)
- [subosito/flutter-action](https://github.com/subosito/flutter-action)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
- [Google Play Upload Action](https://github.com/r0adkll/upload-google-play)

---

**Mis à jour:** 7 mai 2026
