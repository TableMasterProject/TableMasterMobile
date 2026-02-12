class SearchReviews {
  int? offset;
  int? pageSize;

  SearchReviews({
    this.offset,
    this.pageSize = 20, // Valeur par défaut comme dans ton C#
  });

  Map<String, dynamic> toJson() {
    return {
      'Offset': offset,
      'PageSize': pageSize,
    };
  }

  SearchReviews copyWith({
    int? offset,
    int? pageSize,
  }) {
    return SearchReviews(
      offset: offset ?? this.offset,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}