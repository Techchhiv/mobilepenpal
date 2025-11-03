class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;
  final Map<String, dynamic>? error;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
      Map<String, dynamic> json, T Function(dynamic) fromData) {
    return ApiResponse(
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null ? fromData(json['data']) : null,
      error: json['error'] != null
          ? Map<String, dynamic>.from(json['error'])
          : null,
    );
  }
}
