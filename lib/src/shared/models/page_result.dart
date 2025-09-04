// DIDACTIC: PageResult<T> — paginated API response model
// Purpose:
// - Represent paginated lists returned by the API, keeping generic mapping
//   explicit via a `fromJsonT` mapper.
// Contract:
// - `fromJson` accepts a mapper function to deserialize `T` and tolerates
//   empty/204 responses by using empty content lists.
// Edge cases / Notes:
// - Numeric and boolean fields are parsed defensively to accept strings or
//   numbers from inconsistent APIs.

// Implementação manual de PageResult para evitar codegen.

class PageResult<T> {
  const PageResult({
    required this.content,
    required this.number,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    this.last = false,
    this.first = false,
  });

  final List<T> content;
  final int number;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;
  final bool first;

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object?) fromJsonT,
  ) {
    final contentList = (json['content'] as List?) ?? const [];
    int asInt(dynamic v, [int def = 0]) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? def;
      return def;
    }
    bool asBool(dynamic v, [bool def = false]) {
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return def;
    }
    return PageResult<T>(
      content: contentList.map(fromJsonT).toList(),
      number: asInt(json['number']),
      size: asInt(json['size']),
      totalElements: asInt(json['totalElements']),
      totalPages: asInt(json['totalPages']),
      last: asBool(json['last']),
      first: asBool(json['first']),
    );
  }

  Map<String, dynamic> toJson(Object? Function(T) toJsonT) => {
        'content': content.map(toJsonT).toList(),
        'number': number,
        'size': size,
        'totalElements': totalElements,
        'totalPages': totalPages,
        'last': last,
        'first': first,
      };
}
