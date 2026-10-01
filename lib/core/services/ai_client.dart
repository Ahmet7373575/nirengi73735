import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

final Dio _dio = Dio(
  BaseOptions(
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 90),
    sendTimeout: Duration(seconds: 30),
  ),
);

Future<Map<String, dynamic>> callLambdaFunction(
  String endpoint,
  Map<String, dynamic> payload,
) async {
  if (endpoint.isEmpty) throw Exception('AI servisi yapılandırılmamış.');
  try {
    final response = await _dio.post<dynamic>(
      endpoint,
      data: payload,
      options: Options(headers: {
        'Content-Type': 'application/json',
        if (_supabaseAnonKey.isNotEmpty) 'apikey': _supabaseAnonKey,
        if (_supabaseAnonKey.isNotEmpty)
          'Authorization': 'Bearer $_supabaseAnonKey',
      }),
    );
    final data = response.data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('AI servisinden geçersiz yanıt geldi.');
  } on DioException catch (error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      throw Exception('AI isteği zaman aşımına uğradı.');
    }
    if (error.type == DioExceptionType.connectionError) {
      throw Exception('AI servisine bağlanılamadı. İnternet bağlantınızı kontrol edin.');
    }
    final raw = error.response?.data;
    if (error.response?.statusCode == 429) {
      throw Exception('Gemini ücretsiz günlük kullanım kotası doldu. Kota yenilendiğinde tekrar deneyin.');
    }
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final message = map['details'] ?? map['error'];
      if (message != null) {
        debugPrint('Supabase AI error: $message');
        throw Exception('AI sağlayıcısı yanıt vermedi (${error.response?.statusCode ?? 500}).');
      }
    }
    debugPrint('Supabase AI request error: $error');
    throw Exception('AI servisine bağlanılamadı. Lütfen tekrar deneyin.');
  }
}
