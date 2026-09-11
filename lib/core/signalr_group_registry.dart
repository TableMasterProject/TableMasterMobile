/// Suit les groupes SignalR auxquels l'application est abonnée.
///
/// La connexion SignalR est un singleton partagé par tous les écrans, alors que
/// plusieurs écrans peuvent dépendre du même groupe en même temps (par exemple
/// l'écran restaurant et la page des réservations d'une table). Sans comptage de
/// références, le `dispose()` du premier écran fermé quitte le groupe et coupe le
/// temps réel des écrans encore montés.
///
/// Le registre sert aussi de mémoire des adhésions : côté serveur les groupes
/// sont indexés par `ConnectionId`, donc toute reconnexion les perd et il faut
/// pouvoir les rejouer.
class SignalRGroupRegistry {
  final Map<String, int> _refCounts = {};

  /// Enregistre une adhésion au groupe.
  ///
  /// Retourne `true` si c'est la première (0 -> 1), c'est-à-dire s'il faut
  /// réellement invoquer le Join côté serveur.
  bool acquire(String group) {
    final count = (_refCounts[group] ?? 0) + 1;
    _refCounts[group] = count;
    return count == 1;
  }

  /// Libère une adhésion au groupe.
  ///
  /// Retourne `true` si c'était la dernière (1 -> 0), c'est-à-dire s'il faut
  /// réellement invoquer le Leave côté serveur. Retourne `false` si d'autres
  /// écrans dépendent encore du groupe, ou si le groupe n'était pas suivi.
  bool release(String group) {
    final count = _refCounts[group];
    if (count == null) return false;

    if (count <= 1) {
      _refCounts.remove(group);
      return true;
    }

    _refCounts[group] = count - 1;
    return false;
  }

  /// Groupes actuellement actifs, à re-rejoindre après une reconnexion.
  List<String> get activeGroups => List.unmodifiable(_refCounts.keys);

  /// Nombre d'écrans dépendant du groupe (0 si le groupe n'est pas suivi).
  int refCountOf(String group) => _refCounts[group] ?? 0;

  bool contains(String group) => _refCounts.containsKey(group);

  /// Oublie toutes les adhésions (déconnexion utilisateur).
  void clear() => _refCounts.clear();
}
