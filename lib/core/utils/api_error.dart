import 'package:dio/dio.dart';

/// Most specific user-facing message from a Laravel API error envelope:
/// the first per-field validation error, then the envelope `message`,
/// then [fallback]. Network failures get a connectivity message.
String apiErrorMessage(Object error, String fallback) {
  if (error is! DioException) return fallback;

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'The server is taking too long to respond. Please try again.';
    case DioExceptionType.connectionError:
      return 'Could not reach the server. Check your internet connection and try again.';
    default:
      break;
  }

  // Rate-limited (sign-up, OTP, password reset, login): the server's own
  // "Too Many Attempts." does not say what to do next.
  if (error.response?.statusCode == 429) {
    return 'Too many attempts. Please wait a minute and try again.';
  }

  final data = error.response?.data;
  if (data is Map<String, dynamic>) {
    final errors = data['errors'];
    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      final first = errors.values.first;
      return first is List && first.isNotEmpty ? first.first.toString() : first.toString();
    }
    final message = data['message'];
    if (message is String && message.isNotEmpty) return message;
  }
  return fallback;
}
