class SearchReservations {
  int? offset;
  int? pageSize;

  SearchReservations({this.offset, this.pageSize = 20});

  Map<String, dynamic> toJson() {
    return {'Offset': offset, 'PageSize': pageSize};
  }

  SearchReservations copyWith({int? offset, int? pageSize}) {
    return SearchReservations(
      offset: offset ?? this.offset,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
