class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final List<String>? errors;
  final String? timestamp;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
    this.errors,
    this.timestamp,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic data) fromData) {
    return ApiResponse(
      code: (json['code'] is int) ? json['code'] : int.tryParse(json['code']?.toString() ?? '0') ?? 0,
      message: json['message']?.toString() ?? 'Unknown error',
      data: json['data'] != null ? fromData(json['data']) : null,
      errors: (json['errors'] is List) 
          ? (json['errors'] as List).map((e) => e.toString()).toList()
          : null,
      timestamp: json['timestamp']?.toString(),
    );
  }
}