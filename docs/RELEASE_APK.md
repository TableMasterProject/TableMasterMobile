# Procédure de release APK directe

L'APK reste distribué par GitHub Releases. Aucun compte Play Store n'est requis.

## Secrets GitHub obligatoires

- `ANDROID_KEYSTORE_BASE64` : contenu base64 de la clé de signature stable ;
- `ANDROID_KEY_ALIAS` : alias de la clé ;
- `ANDROID_STORE_PASSWORD` : mot de passe du keystore ;
- `ANDROID_KEY_PASSWORD` : mot de passe de la clé ;
- `SENTRY_DSN_FLUTTER` : DSN du projet Flutter existant.

La clé et ses mots de passe ne doivent jamais être copiés dans Git, les logs,
une issue ou le dossier RNCP. Conserver une sauvegarde privée du keystore : sa
perte empêcherait la mise à jour des APK déjà installés.

## Création des secrets

Dans GitHub, ouvrir **Settings > Secrets and variables > Actions**, puis créer
chaque secret avec **New repository secret**. Depuis la racine du dépôt mobile,
les commandes suivantes copient une valeur dans le presse-papiers sans
l'afficher dans le terminal :

```bash
# ANDROID_KEYSTORE_BASE64
base64 -w 0 android/app/upload-keystore.jks | wl-copy

# ANDROID_KEY_ALIAS
sed -n 's/^keyAlias=//p' android/key.properties | tr -d '\n' | wl-copy

# ANDROID_STORE_PASSWORD
sed -n 's/^storePassword=//p' android/key.properties | tr -d '\n' | wl-copy

# ANDROID_KEY_PASSWORD
sed -n 's/^keyPassword=//p' android/key.properties | tr -d '\n' | wl-copy

# Effacer le presse-papiers après le dernier collage
printf '' | wl-copy
```

Exécuter une commande, coller immédiatement sa valeur dans le secret portant le
nom indiqué, puis passer à la suivante. Ne jamais placer ces valeurs dans un
commit, une capture d'écran, un ticket ou un message Discord.

## Contenu d'une release

- version `1.0.2+<numéro du run>` ;
- APK signé avec la clé stable ;
- build web correspondant ;
- commit et release Sentry ;
- rapports de tests et dépendances ;
- `CHANGELOG.md` et `SHA256SUMS`.

## Génération depuis GitHub

Après avoir ajouté les secrets, ouvrir **Actions**, choisir
**Flutter Build & Release**, puis **Run workflow** sur la branche `main`.
Le workflow exécute l'analyse et les tests avant de produire l'APK. Une fois le
run terminé, télécharger `tablemaster-prod.apk` depuis la GitHub Release créée
automatiquement ou depuis l'artefact `flutter-builds`.

## Recette de mise à jour

1. Installer une première release sur un appareil de test.
2. Se connecter et exécuter le scénario de réservation.
3. Installer la release suivante sans désinstaller l'application.
4. Vérifier la conservation de la session et le fonctionnement du scénario.
5. Contrôler la release dans Sentry et consigner le résultat.

Les anciens APK signés par une clé debug différente peuvent nécessiter une
désinstallation unique avant l'adoption de la signature stable.
