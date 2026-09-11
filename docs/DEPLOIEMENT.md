# Manuel de déploiement — TableMasterMobile

> Bloc 2 — C2.4.1 du RNCP39583. Manuel destiné à la publication des releases mobile + web.

L'application Flutter cible **3 plateformes** : Android (Play Store + APK direct), iOS (App Store), et web (servi par Nginx en complément du site vitrine).

---

## 1. Pré-requis

### Outils

| Outil | Version mini | Vérification |
| --- | --- | --- |
| Flutter SDK | **3.7+** | `flutter --version` |
| Android SDK + cmdline-tools | API 34 mini | `flutter doctor` |
| Xcode (iOS uniquement) | 15+ | `xcodebuild -version` |
| Java JDK | 17 | `java -version` |
| Firebase CLI | 13+ | `firebase --version` |
| FlutterFire CLI | dernier | `flutterfire --version` |

Lancer `flutter doctor -v` doit retourner **uniquement** des coches vertes pour les plateformes ciblées.

### Configurations à avoir

| Fichier | Sensible ? | Description |
| --- | :---: | --- |
| `config/dev.json` | non | URL API dev + flags |
| `config/devEmulator.json` | non | URL `10.0.2.2` pour émulateur Android |
| `config/prod.json` | non | URL API prod + flags |
| `SENTRY_DSN` | non secret critique, hors Git | DSN Sentry Flutter injecté au build/run |
| `lib/firebase_options.dart` | non | Généré par `flutterfire configure` |
| `android/keystore/*.jks` | **OUI** | Keystore de signature Android — hors Git |
| `android/key.properties` | **OUI** | Mots de passe keystore — hors Git |
| Apple Developer certificate + provisioning | **OUI** | Géré dans Xcode/Apple Developer Portal |

---

## 2. Builds de release

### 2.1. Android — APK (distribution directe)

```bash
flutter clean
flutter pub get
flutter analyze
flutter test
flutter build apk --release --dart-define-from-file=config/prod.json \
                  --dart-define=SENTRY_DSN=<dsn-flutter> \
                  --obfuscate --split-debug-info=build/symbols/
```

Sortie : `build/app/outputs/flutter-apk/app-release.apk`

### 2.2. Android — App Bundle (Play Store)

```bash
flutter build appbundle --release --dart-define-from-file=config/prod.json \
                        --dart-define=SENTRY_DSN=<dsn-flutter> \
                        --obfuscate --split-debug-info=build/symbols/
```

Sortie : `build/app/outputs/bundle/release/app-release.aab`

Publication :
1. Ouvrir [Play Console](https://play.google.com/console).
2. **Test interne** d'abord (1 jour), puis **Production**.
3. Téléverser le `.aab`, remplir les release notes (issues de `CHANGELOG.md`).
4. Soumettre — délai habituel 1-3 jours.

### 2.3. iOS — IPA (App Store)

```bash
flutter build ipa --release --dart-define-from-file=config/prod.json \
                  --dart-define=SENTRY_DSN=<dsn-flutter> \
                  --obfuscate --split-debug-info=build/symbols/
```

Sortie : `build/ios/ipa/table_master_mobile.ipa`

Publication :
1. Téléverser via **Xcode Organizer** ou `xcrun altool` :
   ```bash
   xcrun altool --upload-app --type ios \
     --file build/ios/ipa/table_master_mobile.ipa \
     --apiKey <KEY_ID> --apiIssuer <ISSUER_ID>
   ```
2. Ouvrir [App Store Connect](https://appstoreconnect.apple.com), passer le build en **TestFlight** d'abord, puis soumettre en review.

### 2.4. Web — PWA

```bash
flutter build web --release --dart-define-from-file=config/prod.json \
                  --dart-define=SENTRY_DSN=<dsn-flutter> \
                  --web-renderer canvaskit
```

Sortie : `build/web/`

Le build de production échoue au démarrage si `API_URL` n'est pas en HTTPS. Ce schéma permet au client SignalR de passer automatiquement en WSS.

Déploiement (servi par Nginx sur `app.tablemaster.lmpe.ovh`) :

```bash
rsync -avz --delete build/web/ deploy@app.tablemaster.lmpe.ovh:/var/www/tablemaster-app/
ssh deploy@app.tablemaster.lmpe.ovh "sudo nginx -t && sudo systemctl reload nginx"
```

Le `nginx.conf` doit servir `index.html` en fallback pour la SPA :

```nginx
location / {
  try_files $uri $uri/ /index.html;
}
```

Le serveur présenté dans le dépôt écoute en HTTP à l'intérieur du réseau de conteneurs. Le reverse proxy public doit terminer TLS. Sur la route `/reservationHub`, ses journaux ne doivent pas enregistrer la query string `access_token`.

Pour une livraison coordonnée, produire et tester ce build avant de sécuriser le hub API. Déployer ensuite les migrations et l'API, puis publier immédiatement cette version Flutter ; les anciennes versions gardent les appels HTTP mais ne reçoivent pas l'invalidation publique de disponibilité.

---

## 3. Versioning

La version applicative est portée par `pubspec.yaml` :

```yaml
version: 1.2.3+45        # nameVersion+buildNumber
```

Convention :
- **Major** (1.x.x) : refonte de l'expérience (ex. nouveau onboarding).
- **Minor** (x.2.x) : nouvelle fonctionnalité utilisateur visible.
- **Patch** (x.x.3) : correctif sans impact UX.
- **Build number** : incrémenté à **chaque** upload store (obligatoire stores).

Avant tout build de release :
```bash
# Incrémenter dans pubspec.yaml puis :
git add pubspec.yaml CHANGELOG.md
git commit -m "release: v1.2.3+45"
git tag v1.2.3+45
git push --follow-tags
```

---

## 4. Rollback / hotfix

### Cas 1 — Régression bloquante en prod

Stores **ne supportent pas** le rollback direct côté Play Store / App Store. Procédure :
1. Identifier le commit/tag stable précédent (`git tag`).
2. `git checkout -b hotfix/1.2.4 v1.2.3+45`.
3. Cherry-pick uniquement les correctifs urgents.
4. Bump version → `1.2.4+46`.
5. Rebuild + soumettre.

Sur Android, la prochaine version peut être promue en **rollout progressif** (5 → 20 → 50 → 100 %) pour limiter le blast radius.

### Cas 2 — Régression sur la version web

Le web déployé est statique, on peut **rollback en 30 secondes** :
```bash
ssh deploy@app.tablemaster.lmpe.ovh
cd /var/www
sudo cp -r tablemaster-app-backup-YYYYMMDD tablemaster-app
sudo systemctl reload nginx
```

(Maintenir une copie horodatée à chaque déploiement.)

---

## 5. Vérifications post-déploiement

### Sanity check par plateforme

| Plateforme | Vérif manuelle |
| --- | --- |
| Android | Installer l'APK ou télécharger depuis Play Store → login → créer une résa → recevoir notification push |
| iOS | TestFlight → login → réservation → push |
| Web | https://app.tablemaster.lmpe.ovh → login → ouvrir une fiche restaurant → vérifier carte Google Maps |
| Sentry | Vérifier qu'une erreur/test remonte dans le projet Sentry Flutter |

### Smoke tests automatiques

Idéalement avant chaque release majeure :
```bash
flutter drive --target=integration_test/smoke_test.dart \
              --dart-define-from-file=config/prod.json
```

---

## 6. Logs et diagnostic

| Plateforme | Source | Commande |
| --- | --- | --- |
| Android | logcat | `adb logcat | grep flutter` |
| iOS | Console.app | filtre sur `TableMaster` |
| Web | DevTools | F12 → Console / Network |
| Toutes plateformes | Sentry Flutter | dashboard cloud |

---

## 7. Cycle de mise à jour Firebase

Quand la configuration Firebase change (nouvelle plateforme, nouveau projet) :

```bash
flutterfire configure
git diff lib/firebase_options.dart    # vérifier
git commit -m "chore: regen firebase options"
```

Ne **pas** commiter les fichiers natifs spécifiques (`google-services.json`, `GoogleService-Info.plist`) s'ils contiennent des identifiants privés — voir `.gitignore`.

---

## 8. Voir aussi

- `README.md` — démarrage local et configuration Firebase.
- `CI_CD.md` — pipeline GitHub Actions.
- `SECURITY.md` — mesures OWASP Mobile.
- `test/README.md` — exécution des tests unitaires.
