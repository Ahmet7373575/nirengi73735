import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../ai_client.dart';

const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _chatCompletionEndpoint = '$_supabaseUrl/functions/v1/chat-completion';
const Duration _connectTimeout = Duration(seconds: 30);
const Duration _receiveTimeout = Duration(seconds: 90);

Map<String, String> _headers() => {
  'Content-Type': 'application/json',
  if (_supabaseAnonKey.isNotEmpty) 'apikey': _supabaseAnonKey,
  if (_supabaseAnonKey.isNotEmpty) 'Authorization': 'Bearer $_supabaseAnonKey',
};

Future<Map<String, dynamic>> getChatCompletion(
  String provider,
  String model,
  List<Map<String, dynamic>> messages, {
  Map<String, dynamic> parameters = const {},
}) async {
  if (_supabaseUrl.isEmpty) throw Exception('Supabase URL yapılandırılmamış.');
  return callLambdaFunction(_chatCompletionEndpoint, {
    'provider': provider,
    'model': model,
    'messages': messages,
    'stream': false,
    'parameters': parameters,
  });
}

Future<void> getStreamingChatCompletion(
  String provider,
  String model,
  List<Map<String, dynamic>> messages, {
  required void Function(Map<String, dynamic> chunk) onChunk,
  required void Function() onComplete,
  required void Function(Exception error) onError,
  Map<String, dynamic> parameters = const {},
}) async {
  if (_supabaseUrl.isEmpty) {
    onError(Exception('Supabase URL yapılandırılmamış.'));
    return;
  }
  try {
    final dio = Dio(BaseOptions(
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _connectTimeout,
    ));
    final response = await dio.post<ResponseBody>(
      _chatCompletionEndpoint,
      data: {
        'provider': provider,
        'model': model,
        'messages': messages,
        'stream': true,
        'parameters': parameters,
      },
      options: Options(headers: _headers(), responseType: ResponseType.stream),
    );
    var buffer = '';
    var completed = false;
    await for (final bytes in response.data!.stream) {
      buffer += utf8.decode(bytes);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();
      for (final line in lines) {
        if (!line.startsWith('data: ')) continue;
        try {
          final data = jsonDecode(line.substring(6)) as Map<String, dynamic>;
          if (data['type'] == 'chunk' && data['chunk'] is Map) {
            onChunk(Map<String, dynamic>.from(data['chunk'] as Map));
          } else if (data['type'] == 'done') {
            completed = true;
            onComplete();
          } else if (data['type'] == 'error') {
            onError(Exception('AI sağlayıcısı yanıt vermedi.'));
          }
        } catch (_) {}
      }
    }
    if (!completed) onComplete();
  } on DioException catch (e) {
    debugPrint('Supabase streaming AI error: $e');
    if (e.response?.statusCode == 429) {
      onError(Exception('Gemini ücretsiz günlük kullanım kotası doldu. Kota yenilendiğinde tekrar deneyin.'));
    } else {
      onError(Exception('AI servisine bağlanılamadı. Lütfen tekrar deneyin.'));
    }
  } catch (e) {
    onError(e is Exception ? e : Exception(e.toString()));
  }
}
