class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final List<String>? errors;
  final Map<String, List<String>>? fieldErrors;
  final String? timestamp;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
    this.errors,
    this.fieldErrors,
    this.timestamp,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic data) fromData,
  ) {
    dynamic rawErrors = json['errors'] ?? json['error'];

    if (rawErrors == null && json['data'] is Map) {
      final dataMap = json['data'] as Map;
      rawErrors = dataMap['errors'] ?? dataMap['error'];
    }

    Map<String, List<String>>? parsedFieldErrors;
    List<String>? parsedFlatErrors;

    if (rawErrors is Map) {
      final map = <String, List<String>>{};
      final flat = <String>[];

      rawErrors.forEach((k, v) {
        final key = k.toString();
        if (v is List) {
          final msgs = v.map((e) => e.toString()).toList();
          map[key] = msgs;
          flat.addAll(msgs);
        } else if (v != null) {
          final msg = v.toString();
          map[key] = [msg];
          flat.add(msg);
        }
      });

      parsedFieldErrors = map.isEmpty ? null : map;
      parsedFlatErrors = flat.isEmpty ? null : flat;
    } else if (rawErrors is List) {
      parsedFlatErrors = rawErrors.map((e) => e.toString()).toList();
    }

    return ApiResponse(
      code: (json['code'] is int)
          ? json['code']
          : int.tryParse(json['code']?.toString() ?? '0') ?? 0,
      message: json['message']?.toString() ?? 'Unknown error',
      data: json['data'] != null ? fromData(json['data']) : null,
      errors: parsedFlatErrors,
      fieldErrors: parsedFieldErrors,
      timestamp: json['timestamp']?.toString(),
    );
  }
}
