import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../ai_client.dart';

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const String _chatCompletionEndpoint = String.fromEnvironment(
  'AI_CHAT_COMPLETION_URL',
);

String get _resolvedChatCompletionEndpoint =>
    _chatCompletionEndpoint.isNotEmpty
        ? _chatCompletionEndpoint
        : (_supabaseUrl.isNotEmpty
              ? '$_supabaseUrl/functions/v1/chat-completion'
              : '');

Map<String, String> get _supabaseFunctionHeaders => {
  'Content-Type': 'application/json',
  if (_supabaseAnonKey.isNotEmpty) ...{
    'apikey': _supabaseAnonKey,
    'Authorization': 'Bearer $_supabaseAnonKey',
  },
};

const Duration _connectTimeout = Duration(seconds: 30);
const Duration _receiveTimeout = Duration(seconds: 90);

Future<Map<String, dynamic>> getChatCompletion(
  String provider,
  String model,
  List<Map<String, dynamic>> messages, {
  Map<String, dynamic> parameters = const {},
}) async {
  final endpoint = _resolvedChatCompletionEndpoint;
  if (endpoint.isEmpty) {
    throw Exception('AI servisi yapılandırılmamış.');
  }
  final payload = {
    'provider': provider,
    'model': model,
    'messages': messages,
    'stream': false,
    'parameters': parameters,
  };
  return await callLambdaFunction(
    endpoint,
    payload,
    headers: _supabaseFunctionHeaders,
  );
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
  final endpoint = _resolvedChatCompletionEndpoint;
  if (endpoint.isEmpty) {
    onError(Exception('AI servisi yapılandırılmamış.'));
    return;
  }

  final payload = {
    'provider': provider,
    'model': model,
    'messages': messages,
    'stream': true,
    'parameters': parameters,
  };

  try {
    final dio = Dio(
      BaseOptions(
        connectTimeout: _connectTimeout,
        receiveTimeout: _receiveTimeout,
        sendTimeout: _connectTimeout,
      ),
    );

    final response = await dio.post<ResponseBody>(
      endpoint,
      data: payload,
      options: Options(
        headers: _supabaseFunctionHeaders,
        responseType: ResponseType.stream,
      ),
    );

    String buffer = '';
    bool completed = false;

    await for (final chunk in response.data!.stream) {
      buffer += utf8.decode(chunk);
      final lines = buffer.split('\n');
      buffer = lines.removeLast();

      for (final line in lines) {
        if (line.startsWith('data: ')) {
          try {
            final data = jsonDecode(line.substring(6)) as Map<String, dynamic>;
            if (data['type'] == 'chunk' && data['chunk'] != null) {
              onChunk(data['chunk'] as Map<String, dynamic>);
            } else if (data['type'] == 'done') {
              completed = true;
              onComplete();
            } else if (data['type'] == 'error') {
              debugPrint(
                'Supabase Function Error: ${data['error']}, details: ${data['details']}',
              );
              onError(Exception(data['error']));
            }
          } catch (_) {
            // Ignore malformed SSE lines.
          }
        }
      }
    }

    if (!completed) onComplete();
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      onError(Exception('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.'));
    } else if (e.type == DioExceptionType.connectionError) {
      onError(Exception('İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.'));
    } else if (e.response?.data is Map && e.response?.data['error'] != null) {
      onError(Exception(e.response?.data['error'].toString()));
    } else {
      onError(Exception('AI servisine bağlanılamadı. Lütfen tekrar deneyin.'));
    }
  } catch (error) {
    debugPrint('Supabase streaming error: $error');
    onError(error is Exception ? error : Exception(error.toString()));
  }
}
