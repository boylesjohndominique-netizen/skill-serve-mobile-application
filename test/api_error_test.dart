import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skillserve_mobile/core/utils/api_error.dart';

DioException _response(int status, Object? data) {
  final options = RequestOptions(path: '/client/v1/auth/login');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('a rate-limited request explains what to do', () {
    final message = apiErrorMessage(
      _response(429, {'success': false, 'message': 'Too Many Attempts.'}),
      'fallback',
    );
    expect(message, 'Too many attempts. Please wait a minute and try again.');
  });

  test('the first validation error wins, then the envelope message, then the fallback', () {
    expect(
      apiErrorMessage(_response(422, {'message': 'Invalid.', 'errors': {'email': ['Enter an email.']}}), 'f'),
      'Enter an email.',
    );
    expect(apiErrorMessage(_response(403, {'message': 'Your account is not active.'}), 'f'),
        'Your account is not active.');
    expect(apiErrorMessage(_response(500, 'oops'), 'fallback'), 'fallback');
  });
}
