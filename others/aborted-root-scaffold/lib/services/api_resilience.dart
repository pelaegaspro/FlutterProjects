import 'dart:math';

import 'package:dio/dio.dart';

class ApiResilience {
  ApiResilience._();

  static final Random _random = Random();

  static Future<T> retry<T>(
    Future<T> Function() operation, {
    int maxAttempts = 3,
    bool Function(Object error)? shouldRetry,
    void Function(Object error, int attempt, Duration delay)? onRetry,
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error;
        final isLastAttempt = attempt >= maxAttempts;
        final retryable = shouldRetry?.call(error) ?? isRetryable(error);

        if (!retryable || isLastAttempt) {
          rethrow;
        }

        final delay = _backoffDelay(attempt);
        onRetry?.call(error, attempt, delay);
        await Future<void>.delayed(delay);
      }
    }

    throw lastError!;
  }

  static bool isRetryable(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          return statusCode == 429 ||
              statusCode == 500 ||
              statusCode == 502 ||
              statusCode == 503 ||
              statusCode == 504;
        case DioExceptionType.cancel:
        case DioExceptionType.badCertificate:
        case DioExceptionType.unknown:
          break;
      }
    }

    final message = error.toString().toUpperCase();
    return message.contains('RATE_LIMIT') ||
        message.contains('SERVICE UNAVAILABLE') ||
        message.contains('UNAVAILABLE') ||
        message.contains('CAPACITY') ||
        message.contains('MODEL_CAPACITY_EXHAUSTED') ||
        message.contains('TIMEOUT');
  }

  static Duration _backoffDelay(int attempt) {
    final baseMilliseconds = 1000 * (1 << (attempt - 1));
    final jitterMilliseconds = _random.nextInt(350);
    return Duration(milliseconds: baseMilliseconds + jitterMilliseconds);
  }
}
