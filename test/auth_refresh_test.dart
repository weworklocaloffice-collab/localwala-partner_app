import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/models/auth_tokens.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthAdapter implements HttpClientAdapter {
  int refreshCalls = 0;
  int oldTokenCalls = 0;
  int freshTokenCalls = 0;
  int logoutCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/logout')) {
      logoutCalls++;
      final String body = await requestStream!.map(utf8.decode).join();
      expect(jsonDecode(body), <String, dynamic>{
        'refreshToken': 'old-refresh',
      });
      return ResponseBody.fromString('{"success":true}', 200);
    }

    if (options.path.endsWith('/refresh-tokens-app')) {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 30));
      return ResponseBody.fromString(
        jsonEncode(<String, dynamic>{
          'access': <String, dynamic>{'token': 'fresh-access'},
          'refresh': <String, dynamic>{'token': 'fresh-refresh'},
        }),
        200,
      );
    }

    if (options.headers['Authorization'] == 'Bearer expired-access') {
      oldTokenCalls++;
      if (options.path.endsWith('/slow')) {
        await Future<void>.delayed(const Duration(milliseconds: 120));
      }
      return ResponseBody.fromString('{"message":"Please authenticate"}', 401);
    }

    if (options.headers['Authorization'] == 'Bearer fresh-access') {
      freshTokenCalls++;
      return ResponseBody.fromString('{"ok":true}', 200);
    }
    return ResponseBody.fromString('{"message":"Please authenticate"}', 401);
  }

  @override
  void close({bool force = false}) {}
}

Future<AuthRepository> _newAuth() async {
  FlutterSecureStorage.setMockInitialValues(<String, String>{});
  SharedPreferences.setMockInitialValues(<String, Object>{
    'old-session': 'user',
  });
  final AuthRepository auth = AuthRepository(
    prefs: await SharedPreferences.getInstance(),
  );
  await auth.saveTokens(accessToken: 'expired-access', refresh: 'old-refresh');
  return auth;
}

Future<DioApiResponse> _request(String path, _AuthAdapter adapter) {
  return ApiRequestService.makeRequest(
    'v1/dairy/$path',
    method: 'GET',
    token: 'expired-access',
    baseUrl: 'https://api.test/',
    httpClientAdapter: adapter,
  );
}

void main() {
  test(
    'simultaneous 401s share refresh, rotate tokens, and each retry once',
    () async {
      final AuthRepository auth = await _newAuth();
      final _AuthAdapter adapter = _AuthAdapter();
      final List<DioApiResponse> responses = await Future.wait(
        List<Future<DioApiResponse>>.generate(
          7,
          (int _) => _request('orders', adapter),
        ),
      );

      expect(
        responses.every((DioApiResponse r) => r.errorType == NetErrorType.none),
        isTrue,
      );
      expect(adapter.oldTokenCalls, 7);
      expect(adapter.refreshCalls, 1);
      expect(adapter.freshTokenCalls, 7);
      expect(AuthTokens.readToken(await auth.authToken()), 'fresh-access');
      expect(AuthTokens.readToken(await auth.refreshToken()), 'fresh-refresh');
    },
  );

  test(
    'a late 401 reuses the completed refresh instead of rotating again',
    () async {
      await _newAuth();
      final _AuthAdapter adapter = _AuthAdapter();
      final Future<DioApiResponse> slow = _request('slow', adapter);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final DioApiResponse fast = await _request('fast', adapter);
      final DioApiResponse late = await slow;

      expect(fast.errorType, NetErrorType.none);
      expect(late.errorType, NetErrorType.none);
      expect(adapter.refreshCalls, 1);
      expect(adapter.freshTokenCalls, 2);
    },
  );

  test(
    'a malformed cached token is cleared locally without calling logout',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        '_dairyAuthToken': '{token: bad, expires: later}',
        '_dairyAuthRefreshToken': '{token: bad-refresh, expires: later}',
      });
      SharedPreferences.setMockInitialValues(<String, Object>{
        'old-session': 'user',
      });
      final AuthRepository auth = AuthRepository(
        prefs: await SharedPreferences.getInstance(),
      );

      expect(await auth.isLoggedIn(), isFalse);
      expect(await auth.authToken(), isNull);
      expect(await auth.refreshToken(), isNull);
    },
  );

  test(
    'logout clears the local session even when the refresh token is malformed',
    () async {
      FlutterSecureStorage.setMockInitialValues(<String, String>{
        '_dairyAuthToken': 'access-jwt',
        '_dairyAuthRefreshToken': '{token: bad, expires: later}',
      });
      SharedPreferences.setMockInitialValues(<String, Object>{
        'old-session': 'user',
      });
      final AuthRepository auth = AuthRepository(
        prefs: await SharedPreferences.getInstance(),
      );
      await auth.logout();

      expect(await auth.authToken(), isNull);
      expect(await auth.refreshToken(), isNull);
    },
  );

  test('logout revokes the valid refresh token and clears local credentials', () async {
    final AuthRepository auth = await _newAuth();
    final _AuthAdapter adapter = _AuthAdapter();

    await auth.logout(baseUrl: 'https://api.test/', httpClientAdapter: adapter);

    expect(adapter.logoutCalls, 1);
    expect(await auth.authToken(), isNull);
    expect(await auth.refreshToken(), isNull);
  });
}
