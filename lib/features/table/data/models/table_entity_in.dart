class TableEntityIn {
  int restaurantId;
  int tableNumber;
  int numberOfSeats;

  TableEntityIn({
    required this.restaurantId,
    required this.tableNumber,
    required this.numberOfSeats,
  });

  // Conversion de l'objet vers JSON pour ton API .NET
  Map<String, dynamic> toJson() {
    return {
      'RestaurantId': restaurantId,
      'TableNumber': tableNumber,
      'NumberOfSeats': numberOfSeats,
    };
  }

  // Méthode copyWith pour TableEntityIn
  TableEntityIn copyWith({
    int? restaurantId,
    int? tableNumber,
    int? numberOfSeats,
  }) {
    return TableEntityIn(
      restaurantId: restaurantId ?? this.restaurantId,
      tableNumber: tableNumber ?? this.tableNumber,
      numberOfSeats: numberOfSeats ?? this.numberOfSeats,
    );
  }
}