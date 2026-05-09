import 'package:table_master_mobile/features/user/data/models/user_in.dart';


class UserOut extends UserIn {
  int id;
  DateTime createdAt;
  int? restaurantId;

  UserOut({
    required super.email,
    required super.password,
    required super.firstName,
    required super.lastName,
    required super.accountType,
    required this.id,
    required this.createdAt,
    this.restaurantId,
  });

  // Constructeur pour transformer le JSON du serveur en objet Dart
  factory UserOut.fromJson(Map<String, dynamic> json) {
    return UserOut(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      password: '', // Souvent vide ou non renvoyé par l'API pour la sécurité
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      accountType: json['accountType'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      restaurantId: json['restaurantId'],
    );
  }
}