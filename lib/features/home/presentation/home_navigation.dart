class HomeNavigation {
  const HomeNavigation._(this.isRestaurant);

  factory HomeNavigation.forAccountType(int accountType) =>
      HomeNavigation._(accountType == 1);

  final bool isRestaurant;
  int get initialIndex => 0;
  List<String> get labels =>
      isRestaurant
          ? const ['Service', 'Tables', 'Compte']
          : const ['Découvrir', 'Mes réservations', 'Compte'];
}
