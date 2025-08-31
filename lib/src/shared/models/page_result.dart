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
    int _asInt(dynamic v, [int def = 0]) {
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? def;
      return def;
    }
    bool _asBool(dynamic v, [bool def = false]) {
      if (v is bool) return v;
      if (v is String) return v.toLowerCase() == 'true';
      return def;
    }
    return PageResult<T>(
      content: contentList.map(fromJsonT).toList(),
      number: _asInt(json['number']),
      size: _asInt(json['size']),
      totalElements: _asInt(json['totalElements']),
      totalPages: _asInt(json['totalPages']),
      last: _asBool(json['last']),
      first: _asBool(json['first']),
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
