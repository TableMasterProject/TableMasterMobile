class MenuIn {
  int restaurantId;
  String category;
  String itemName;
  String description;
  double price;

  MenuIn({
    required this.restaurantId,
    required this.category,
    required this.itemName,
    required this.description,
    required this.price,
  });

  // Pour envoyer les données à l'API
  Map<String, dynamic> toJson() {
    return {
      'RestaurantId': restaurantId,
      'Category': category,
      'ItemName': itemName,
      'Description': description,
      'Price': price,
    };
  }

  // La méthode copyWith pour cloner l'objet avec des modifications
  MenuIn copyWith({
    int? restaurantId,
    String? category,
    String? itemName,
    String? description,
    double? price,
  }) {
    return MenuIn(
      restaurantId: restaurantId ?? this.restaurantId,
      category: category ?? this.category,
      itemName: itemName ?? this.itemName,
      description: description ?? this.description,
      price: price ?? this.price,
    );
  }
}
