import 'dart:async';

import 'package:amber_mobile_client/core/network/api_client.dart';
import 'package:amber_mobile_client/features/auth/data/account.dart';
import 'package:amber_mobile_client/features/auth/data/auth_api.dart';
import 'package:amber_mobile_client/features/auth/data/auth_failure.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AuthStatus {
  /// Restoring the session on launch.
  unknown,

  /// The session could not be checked because the server was unreachable.
  unreachable,
  unauthenticated,
  authenticated,
}

class AuthState {
  const AuthState({this.status = AuthStatus.unknown, this.account});

  final AuthStatus status;
  final Account? account;

  bool get needsVerification =>
      status == AuthStatus.authenticated && account?.verified == false;
}

/// Owns the signed-in session: launch restore, login, register, sign-out,
/// and keeping the realtime connection in step with it.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required this._api,
    required this._client,
    required this._connectRealtime,
    required this._disconnectRealtime,
    Stream<Map<String, dynamic>> accountEvents = const Stream.empty(),
  }) : super(const AuthState()) {
    _client.onSessionExpired = _onSessionExpired;
    _accountEvents = accountEvents.listen(_onAccountEvent);
  }

  final AuthApi _api;
  final ApiClient _client;
  final Future<void> Function() _connectRealtime;
  final Future<void> Function() _disconnectRealtime;
  late final StreamSubscription<Map<String, dynamic>> _accountEvents;

  /// Restores the session from secure storage on launch.
  Future<void> start() async {
    emit(const AuthState());
    try {
      if (!await _client.restoreSession()) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
        return;
      }
      await _loadAccount();
    } on DioException {
      emit(const AuthState(status: AuthStatus.unreachable));
    } on AuthFailure catch (failure) {
      emit(
        AuthState(
          status: failure.messageKey == AuthFailure.unreachable
              ? AuthStatus.unreachable
              : AuthStatus.unauthenticated,
        ),
      );
    }
  }

  /// Throws [AuthFailure] so the login screen can show the message.
  Future<void> login(String username, String password) async {
    await _api.login(username, password);
    await _loadAccount();
  }

  /// Registers, then logs in with the same credentials.
  Future<void> register({
    required String username,
    required String fullName,
    required String email,
    required String password,
  }) async {
    await _api.register(
      username: username,
      fullName: fullName,
      email: email,
      password: password,
    );
    await login(username, password);
  }

  /// Reloads the account, for example after verifying it.
  Future<void> refreshAccount() async {
    final account = await _api.fetchAccount();
    emit(AuthState(status: AuthStatus.authenticated, account: account));
  }

  /// Emails a verification code. Throws [AuthFailure].
  Future<void> requestVerification() => _api.requestVerification();

  /// Verifies the account with [code], then reloads it. The backend also
  /// pushes `account.updated`, but the reload does not depend on it.
  Future<void> verify(String code) async {
    await _api.verify(code);
    await refreshAccount();
  }

  Future<void> signOut() async {
    await _disconnectRealtime();
    await _client.signOut();
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _loadAccount() async {
    await refreshAccount();
    await _connectRealtime();
  }

  void _onSessionExpired() {
    unawaited(_disconnectRealtime());
    if (!isClosed) emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  /// Applies `account.updated` pushes, which carry `verified` in `payload`.
  void _onAccountEvent(Map<String, dynamic> event) {
    final account = state.account;
    final payload = event['payload'];
    if (account == null || payload is! Map || payload['verified'] is! bool) {
      return;
    }
    emit(
      AuthState(
        status: state.status,
        account: account.copyWith(verified: payload['verified'] as bool),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _accountEvents.cancel();
    if (_client.onSessionExpired == _onSessionExpired) {
      _client.onSessionExpired = null;
    }
    return super.close();
  }
}
