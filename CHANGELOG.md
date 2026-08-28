# Journal des versions de TableMaster Mobile

Les releases Android et web sont reliées à un commit, un run CI et une release
Sentry. Les anomalies corrigées doivent référencer leur issue dans le dépôt API.

## [1.0.2+48] - 2026-08-09

### Ajouté

- Release Sentry explicite alignée avec la version de l'APK.
- APK signé avec une clé de release stable injectée par GitHub Secrets.
- Somme SHA-256, résultats de tests et journal joints à GitHub Releases.
- Suivi Dependabot des dépendances Flutter, Docker et GitHub Actions.

### Modifié

- Numéro de build Android unique basé sur le numéro de run GitHub Actions.
- Tag de release au format `mobile-v1.0.2+<run>`.

### Validation

- `flutter analyze`, formatage, 41 tests, build web et APK release réussis.
- APK `tablemaster-prod.apk` signé avec la clé stable, checksum SHA-256 validé.
- Certificat contrôlé avec `apksigner` et conforme à l'empreinte attendue.
- Web déployé sur le VPS et recette APK confirmée par le candidat.

## [1.0.1] - 2026-07-14

### Ajouté

- Sentry Flutter, navigation instrumentée, builds web/APK et GitHub Releases.

[1.0.2+48]: https://github.com/TableMasterProject/TableMasterMobile/releases/tag/mobile-v1.0.2%2B48
[1.0.1]: https://github.com/TableMasterProject/TableMasterMobile/commit/319bf2019d58aa2a40330238d3ce22c85cb55c9f
