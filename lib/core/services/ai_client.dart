import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

final Dio _dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 90),
    sendTimeout: const Duration(seconds: 30),
  ),
);

Future<Map<String, dynamic>> callLambdaFunction(
  String endpoint,
  Map<String, dynamic> payload,
) async {
  if (endpoint.isEmpty) {
    throw Exception('AI servisi yapılandırılmamış.');
  }
  try {
    final response = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: payload,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    return response.data ?? {};
  } on DioException catch (error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      throw Exception('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
    }
    if (error.type == DioExceptionType.connectionError) {
      throw Exception(
        'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.',
      );
    }
    if (error.response?.data != null && error.response?.data is Map) {
      final data = error.response?.data as Map<String, dynamic>;
      if (data['error'] != null) {
        debugPrint(
          'Lambda Function Error: ${data['error']}, details: ${data['details']}',
        );
        throw Exception(data['error']);
      }
    }
    debugPrint('Lambda function error: $error');
    rethrow;
  }
}
