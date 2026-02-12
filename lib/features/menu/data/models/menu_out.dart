import 'menu_in.dart';

class MenuOut extends MenuIn {
  int id;
  DateTime createdAt;

  MenuOut({
    required super.restaurantId,
    required super.category,
    required super.itemName,
    required super.description,
    required super.price,
    required this.id,
    required this.createdAt,
  });

  factory MenuOut.fromJson(Map<String, dynamic> json) {
    return MenuOut(
      id: json['id'] ?? 0,
      restaurantId: json['restaurantId'] ?? 0,
      category: json['category'] ?? '',
      itemName: json['itemName'] ?? '',
      description: json['description'] ?? '',
      // Gestion du type decimal C# vers double Dart
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }
}
