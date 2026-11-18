import 'package:amber_mobile_client/features/auth/data/auth_failure.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

DioException _error({int? status, Object? data}) {
  final options = RequestOptions(path: '/auth/v1/login');
  return DioException(
    requestOptions: options,
    type: status == null
        ? DioExceptionType.connectionError
        : DioExceptionType.badResponse,
    response: status == null
        ? null
        : Response(requestOptions: options, statusCode: status, data: data),
  );
}

void main() {
  test('uses a string detail as the message key', () {
    final failure = AuthFailure.fromDio(
      _error(status: 401, data: {'detail': 'login.incorrectCredentials'}),
    );

    expect(failure.messageKey, 'login.incorrectCredentials');
    expect(failure.fieldErrors, isEmpty);
  });

  test('maps register field errors', () {
    final failure = AuthFailure.fromDio(
      _error(
        status: 422,
        data: {
          'detail': {
            'errors': [
              {'field': 'username', 'error': 'register.usernameTaken'},
              {'field': 'email', 'error': 'register.invalidEmail'},
            ],
          },
        },
      ),
    );

    expect(failure.fieldErrors, {
      'username': 'register.usernameTaken',
      'email': 'register.invalidEmail',
    });
    expect(failure.messageKey, 'register.usernameTaken');
  });

  test('maps FastAPI validation errors to fill input', () {
    final failure = AuthFailure.fromDio(
      _error(
        status: 422,
        data: {
          'detail': [
            {
              'loc': ['body', 'username'],
              'msg': 'Field required',
            },
          ],
        },
      ),
    );

    expect(failure.messageKey, AuthFailure.fillInput);
  });

  test('maps a 429 without detail to too many requests', () {
    final failure = AuthFailure.fromDio(
      _error(status: 429, data: {'error': 'Rate limit exceeded'}),
    );

    expect(failure.messageKey, AuthFailure.tooManyRequests);
  });

  test('keeps a 429 detail when the backend sends one', () {
    final failure = AuthFailure.fromDio(
      _error(status: 429, data: {'detail': 'login.locked'}),
    );

    expect(failure.messageKey, 'login.locked');
  });

  test('reports network errors as unreachable', () {
    expect(AuthFailure.fromDio(_error()).messageKey, AuthFailure.unreachable);
  });

  test('falls back to the status code for unknown bodies', () {
    final failure = AuthFailure.fromDio(_error(status: 500, data: 'oops'));

    expect(failure.messageKey, 'Request failed (500)');
  });
}
