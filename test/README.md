# Tests — TableMaster Mobile

## Lancer

```bash
flutter pub get
flutter test
flutter test --coverage   # rapport dans coverage/lcov.info
```

## Pattern adopté

Pour chaque feature, deux types de tests minimum :

1. **Repository / Datasource** — délégation et logique de transformation, dépendances mockées via `mocktail`.
2. **Modèle (`fromJson` / `toJson`)** ou **widget standalone** — sérialisation ou rendu UI sans dépendances externes.

Les tests **n'effectuent jamais** d'appel réseau réel — le datasource est mocké via `mocktail`.

## Couverture actuelle

| Feature       | Repository | Modèle | Widget |
| ------------- | :--------: | :----: | :----: |
| auth          |     —      |   ✅    |   —    |
| reservation   |     ✅      |   —    |   ✅    |
| restaurant    |     ✅      |   ✅    |   —    |
| user          |     ✅      |   ✅    |   —    |

## Étendre à une feature non couverte

Recopier `test/features/reservation/reservation_repository_test.dart`, remplacer le datasource et les méthodes, ajuster les fixtures.

## Conventions

- Une classe `Mock<Nom>` par dépendance.
- `setUpAll()` pour les `registerFallbackValue` mocktail si nécessaire.
- Fixtures JSON inline plutôt que dans des fichiers séparés tant qu'on reste sous ~30 lignes.
