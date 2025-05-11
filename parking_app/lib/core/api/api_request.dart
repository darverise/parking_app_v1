abstract class ApiRequest {
  Map<String, dynamic> toJson();
  bool validate();
}

class PaginationRequest extends ApiRequest {
  final int page;
  final int pageSize;
  final String? search;
  final String? sort;

  PaginationRequest({
    this.page = 1,
    this.pageSize = 20,
    this.search,
    this.sort,
  });

  @override
  Map<String, dynamic> toJson() => {
    'page': page,
    'pageSize': pageSize,
    if (search != null) 'search': search,
    if (sort != null) 'sort': sort,
  };

  @override
  bool validate() => page > 0 && pageSize > 0;
}
