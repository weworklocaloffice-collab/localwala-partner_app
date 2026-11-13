import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/models/auth_tokens.dart';
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:partner/app/presentation/pages/auth/login/bloc/login_bloc.dart';

class _AuthRepository extends AuthRepository {
  String? access;
  String? refresh;
  UserSessionModel? savedSession;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refresh,
  }) async {
    access = accessToken;
    this.refresh = refresh;
  }

  @override
  Future<void> saveSession(UserSessionModel session) async {
    savedSession = session;
  }
}

Future<LoginState> _dispatch(
  LoginBloc bloc,
  LoginEvent event,
  bool Function(LoginState) ready,
) async {
  final Future<LoginState> next = bloc.stream.firstWhere(ready);
  bloc.add(event);
  return next.timeout(const Duration(seconds: 5));
}

void main() {
  group('AuthTokens', () {
    test('extracts nested JWT strings from login responses', () {
      final AuthTokens? tokens = AuthTokens.tryParse(<String, dynamic>{
        'tokens': <String, dynamic>{
          'access': <String, dynamic>{
            'token': 'access-jwt',
            'expires': 'later',
          },
          'refresh': <String, dynamic>{
            'token': 'refresh-jwt',
            'expires': 'later',
          },
        },
      });
      expect(tokens?.access, 'access-jwt');
      expect(tokens?.refresh, 'refresh-jwt');
    });

    test(
      'parses top-level refresh responses and rejects token maps as strings',
      () {
        expect(
          AuthTokens.tryParse(<String, dynamic>{
            'access': <String, dynamic>{'token': 'new-access'},
            'refresh': <String, dynamic>{'token': 'new-refresh'},
          })?.access,
          'new-access',
        );
        expect(AuthTokens.readToken('{token: bad, expires: tomorrow}'), isNull);
        expect(
          AuthTokens.tryParse(<String, dynamic>{'access': <String, dynamic>{}}),
          isNull,
        );
        expect(
          AuthTokens.tryParse(<String, dynamic>{'statusCode': 401}),
          isNull,
        );
      },
    );
  });

  test(
    'login saves actual token strings and still persists the user session',
    () async {
      final _AuthRepository auth = _AuthRepository();
      final List<String> requests = <String>[];
      final LoginBloc bloc = LoginBloc(
        authRepository: auth,
        request:
            (
              String endpoint, {
              String method = 'POST',
              Map<String, dynamic>? body,
            }) async {
              requests.add(endpoint);
              if (endpoint == 'v1/auth/partner_app/login_po_verification') {
                return const DioApiResponse.success(
                  '{"id":"otp-1","provider":"app"}',
                );
              }
              if (endpoint == 'v1/auth/verifyOTP') {
                return const DioApiResponse.success('{}');
              }
              return DioApiResponse.success(
                jsonEncode(<String, dynamic>{
                  'user': <String, dynamic>{
                    'id': 'user-1',
                    'role': 'dairyPartner',
                  },
                  'verticals': <String>['dairy'],
                  'tokens': <String, dynamic>{
                    'access': <String, dynamic>{
                      'token': 'access-jwt',
                      'expires': 'later',
                    },
                    'refresh': <String, dynamic>{
                      'token': 'refresh-jwt',
                      'expires': 'later',
                    },
                  },
                }),
              );
            },
      );
      addTearDown(bloc.close);

      await _dispatch(
        bloc,
        const LoginSendOtpEvent('9876543210'),
        (s) => s.otpId != null,
      );
      final LoginState completed = await _dispatch(
        bloc,
        const LoginVerifyOtpEvent('otp-1', '123456'),
        (s) => s.status == LoginStatus.success,
      );

      expect(completed.status, LoginStatus.success);
      expect(requests, <String>[
        'v1/auth/partner_app/login_po_verification',
        'v1/auth/verifyOTP',
        'v1/auth/partner_app/login_po/',
      ]);
      expect(auth.access, 'access-jwt');
      expect(auth.refresh, 'refresh-jwt');
      expect(auth.savedSession?.id, 'user-1');
      expect(auth.savedSession?.role, 'dairyPartner');
    },
  );

  test(
    'malformed login token response does not persist an invalid session',
    () async {
      final _AuthRepository auth = _AuthRepository();
      final LoginBloc bloc = LoginBloc(
        authRepository: auth,
        request:
            (
              String endpoint, {
              String method = 'POST',
              Map<String, dynamic>? body,
            }) async {
              if (endpoint.endsWith('login_po_verification')) {
                return const DioApiResponse.success(
                  '{"id":"otp-1","provider":"app"}',
                );
              }
              if (endpoint.endsWith('verifyOTP')) {
                return const DioApiResponse.success('{}');
              }
              return const DioApiResponse.success(
                '{"tokens":{"access":{"expires":"later"}}}',
              );
            },
      );
      addTearDown(bloc.close);

      await _dispatch(
        bloc,
        const LoginSendOtpEvent('9876543210'),
        (s) => s.otpId != null,
      );
      final LoginState failed = await _dispatch(
        bloc,
        const LoginVerifyOtpEvent('otp-1', '123456'),
        (s) => s.status == LoginStatus.failure,
      );
      expect(failed.alertMessage, 'Token missing');
      expect(auth.access, isNull);
      expect(auth.savedSession, isNull);
    },
  );
}
