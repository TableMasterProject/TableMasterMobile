import 'package:table_master_mobile/features/reservation/data/models/reservation_in.dart';

class SearchReservations {
  int? offset;
  int? pageSize;
  int? tableId;
  List<ReservationStatus>? statuses;
  DateTime? minDate;
  DateTime? maxDate;
  int? idUser;
  int? restaurantId;

  SearchReservations({
    this.offset = 0,
    this.pageSize = 20,
    this.tableId,
    this.statuses,
    this.minDate,
    this.maxDate,
    this.idUser,
    this.restaurantId,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    // Pagination
    if (offset != null) data['Offset'] = offset;
    if (pageSize != null) data['PageSize'] = pageSize;

    // Identifiants
    if (tableId != null) data['tableId'] = tableId;
    if (idUser != null) data['IdUser'] = idUser;
    if (restaurantId != null) data['restaurantId'] = restaurantId;

    // Status (conversion de l'enum en liste d'entiers)
    if (statuses != null && statuses!.isNotEmpty) {
      data['Statuses'] = statuses!.map((e) => e.index).toList();
    }

    // Dates (formatage DateOnly pour C#)
    if (minDate != null) {
      data['minDate'] = minDate!.toIso8601String().split('T')[0];
    }
    if (maxDate != null) {
      data['maxDate'] = maxDate!.toIso8601String().split('T')[0];
    }

    return data;
  }

  SearchReservations copyWith({
    int? offset,
    int? pageSize,
    int? tableId,
    List<ReservationStatus>? statuses,
    DateTime? minDate,
    DateTime? maxDate,
    int? idUser,
    int? restaurantId,
  }) {
    return SearchReservations(
      offset: offset ?? this.offset,
      pageSize: pageSize ?? this.pageSize,
      tableId: tableId ?? this.tableId,
      statuses: statuses ?? this.statuses,
      minDate: minDate ?? this.minDate,
      maxDate: maxDate ?? this.maxDate,
      idUser: idUser ?? this.idUser,
      restaurantId: restaurantId ?? this.restaurantId,
    );
  }
}