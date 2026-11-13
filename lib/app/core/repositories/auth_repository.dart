/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 *
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

import 'dart:convert';

import 'package:partner/app/core/config/api_endpoints.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/config/realestate_endpoints.dart';
import 'package:partner/app/core/config/shared_pref_keys.dart';
import 'package:partner/app/core/models/auth_tokens.dart';
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:dio/dio.dart' show HttpClientAdapter;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepository {
  AuthRepository({SharedPreferences? prefs}) : _injected = prefs;

  final SharedPreferences? _injected;

  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  // Repositories are created per screen/request, but the stored session is shared.
  static int _sessionVersion = 0;
  static int get sessionVersion => _sessionVersion;
  static ({int version, Future<bool> future})? _refreshInFlight;
  static Future<void> _sessionWrites = Future<void>.value();

  Future<void> _writeSession(Future<void> Function() operation) {
    final Future<void> result = _sessionWrites.then((_) => operation());
    _sessionWrites = result.catchError((Object _) {});
    return result;
  }

  Future<SharedPreferences> get _prefs async =>
      _injected ?? await SharedPreferences.getInstance();

  AuthKeys get _k => SharedPreferencesKey.authKeys;

  //// Tokens ////

  Future<String?> authToken() async => await _secure.read(key: _k.authToken);

  Future<String?> refreshToken() async =>
      await _secure.read(key: _k.authRefreshToken);

  Future<String?> uid() async => (await _prefs).getString(_k.uid);

  Future<String?> locale() async => (await _prefs).getString(_k.locale) ?? 'en';

  Future<bool> isLoggedIn() async {
    final String? token = await authToken();
    if (AuthTokens.readToken(token) != null) return true;
    if (token != null) await clearSession();
    return false;
  }

  /// Persists the bearer tokens returned by `POST /v1/auth/dairy/login_po/`.
  ///
  /// Must run before any `/v1/dairy/**` call so the `Authorization` header is
  /// populated.
  Future<void> saveTokens({
    required String accessToken,
    String? refresh,
  }) async {
    final String? access = AuthTokens.readToken(accessToken);
    final String? refreshValue = AuthTokens.readToken(refresh);
    if (access == null || (refresh != null && refreshValue == null)) {
      throw ArgumentError('Invalid authentication token response');
    }
    final int version = ++_sessionVersion;
    await _writeSession(() async {
      if (version != _sessionVersion) return;
      await _storeTokens(AuthTokens(access: access, refresh: refreshValue));
    });
  }

  Future<void> _storeTokens(AuthTokens tokens) async {
    if (tokens.refresh != null) {
      await _secure.write(key: _k.authRefreshToken, value: tokens.refresh);
    } else {
      await _secure.delete(key: _k.authRefreshToken);
    }
    await _secure.write(key: _k.authToken, value: tokens.access);
  }

  //// Session ////

  Future<UserSessionModel?> session() async {
    final SharedPreferences prefs = await _prefs;
    final String? raw = prefs.getString(_k.session);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserSessionModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession(UserSessionModel session) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(_k.session, jsonEncode(session.toJson()));
    await prefs.setString(_k.uid, session.id);
    await prefs.setString(_k.activeRole, session.activeRole.wire);
    await prefs.setStringList(
      _k.availableRoles,
      session.availableRoles.map((DairyAppRole e) => e.wire).toList(),
    );
  }

  Future<void> saveActiveRole(DairyAppRole role) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(_k.activeRole, role.wire);
    final UserSessionModel? current = await session();
    if (current != null) {
      await prefs.setString(
        _k.session,
        jsonEncode(current.copyWith(activeRole: role).toJson()),
      );
    }
  }

  /// Persists the vertical chosen in `shell/vertical_picker/`.
  ///
  /// The choice lives inside the session JSON only — no separate preference
  /// key — so `logout()` clears it with every other session field.
  Future<void> saveActiveVertical(String vertical) async {
    final UserSessionModel? current = await session();
    if (current == null) return;
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(
      _k.session,
      jsonEncode(current.copyWith(activeVertical: vertical).toJson()),
    );
  }

  /// Persists the realestate shell chosen in the role gate.
  ///
  /// Client-side only — there is no server switch-role call for shells.
  /// The server enforces rights per request regardless.
  Future<void> saveActiveRealEstateShell(String shell) async {
    final UserSessionModel? current = await session();
    if (current == null) return;
    final SharedPreferences prefs = await _prefs;
    await prefs.setString(
      _k.session,
      jsonEncode(current.copyWith(activeRealEstateShell: shell).toJson()),
    );
  }

  //// Vertical discovery (offline tolerant) ////

  /// Probes one actor endpoint: 200 means the session holds that shell.
  ///
  /// 404/403 is a definitive "no". Anything else (offline, dead token,
  /// server error) is unknown — null — so the caller keeps the cached
  /// session instead of wiping a choice it cannot re-derive.
  Future<bool?> _probeShell(String endpoint, String token) async {
    final DioApiResponse response = await ApiRequestService.makeRequest(
      endpoint,
      method: 'GET',
      token: token,
    );
    if (response.errorType == NetErrorType.none) return true;
    if (response.errorType == NetErrorType.notFound ||
        response.errorType == NetErrorType.forbidden) {
      return false;
    }
    return null;
  }

  /// Discovers which verticals — and which realestate shells — this
  /// session may enter, by probing the actor endpoints with the session
  /// token. Dairy is always available; realestate arrives one shell at
  /// a time (`vendor`, `executive`); local_services arrives when the
  /// session holds a provider profile (`GET .../partner/providers` 200).
  ///
  /// Returns null when nothing definitive came back (offline), so the
  /// role gate keeps the cached session. Returns dairy-only when all
  /// probes definitively refuse.
  Future<({List<String> verticals, List<String> shells})?>
  fetchAvailableVerticals() async {
    final String? token = await authToken();
    if (token == null || token.isEmpty) return null;

    final UserSessionModel? current = await session();

    final bool? jhatka = await _probeShell(
      JhatkaAuthEndpoints.availableRoles,
      token,
    );
    final bool? vendor = await _probeShell(RealEstateEndpoints.vendorMe, token);
    final bool? executive = await _probeShell(
      RealEstateEndpoints.executiveMe,
      token,
    );
    final bool? lsProvider = await _probeShell(
      'v1/local-services/partner/providers',
      token,
    );
    final bool? storePartner = await _probeShell(
      'v1/stores/partner/scope',
      token,
    );
    if (jhatka == null ||
        vendor == null ||
        executive == null ||
        lsProvider == null ||
        storePartner == null) {
      return null;
    }

    // Start from the cached (login-provided) verticals so verticals we
    // cannot probe (stores) survive a refresh instead of being wiped.
    final List<String> verticals = <String>[...?current?.availableVerticals];
    if (!verticals.contains('dairy')) verticals.add('dairy');
    if (jhatka) {
      if (!verticals.contains('jhatka')) verticals.add('jhatka');
    } else {
      verticals.remove('jhatka');
    }
    final List<String> shells = <String>[];
    if (vendor) {
      if (!verticals.contains('realestate')) verticals.add('realestate');
      shells.add('vendor');
    }
    if (executive) {
      if (!verticals.contains('realestate')) verticals.add('realestate');
      if (!shells.contains('executive')) shells.add('executive');
    }
    if (!vendor && !executive) verticals.remove('realestate');
    if (lsProvider) {
      if (!verticals.contains('local_services')) {
        verticals.add('local_services');
      }
    } else {
      verticals.remove('local_services');
    }
    if (storePartner) {
      if (!verticals.contains('stores')) verticals.add('stores');
    } else {
      verticals.remove('stores');
    }
    return (verticals: verticals, shells: shells);
  }

  //// Server reads (offline tolerant) ////

  /// Fetches the dairy roles this session may render.
  ///
  /// Returns null on any failure so a cached session stays usable — a rider may
  /// be offline for the whole route.
  Future<UserSessionModel?> fetchAvailableRoles() async {
    final String? userId = await uid();
    if (userId == null) return null;

    final UserSessionModel? current = await session();
    final bool isJhatka =
        (current?.role ?? '').startsWith('jhatka') ||
        current?.activeVertical == 'jhatka';

    final DioApiResponse response = await ApiRequestService.makeRequest(
      isJhatka
          ? JhatkaAuthEndpoints.availableRoles
          : DairyPartnerEndpoints.availableRoles,
      method: 'GET',
      token: await authToken(),
      body: <String, dynamic>{'id': userId},
    );
    if (response.errorType != NetErrorType.none ||
        (response.body?.isEmpty ?? true)) {
      return null;
    }

    try {
      final Map<String, dynamic> decoded =
          jsonDecode(response.body!) as Map<String, dynamic>;
      final Map<String, dynamic> roles = decoded['roles'] is Map
          ? Map<String, dynamic>.from(decoded['roles'] as Map)
          : <String, dynamic>{};

      return UserSessionModel.fromJson(<String, dynamic>{
        ...decoded,
        'availableRoles': roles['available'] ?? decoded['availableRoles'],
        'activeRole': roles['active'] ?? decoded['activeRole'],
        'ownDeliveryPartner':
            roles['ownDeliveryPartner'] ?? decoded['ownDeliveryPartner'],
        'driverPayoutMode':
            roles['driverPayoutMode'] ?? decoded['driverPayoutMode'],
        'dairyDriver': roles['dairyDriver'] ?? decoded['dairyDriver'],
        'business': roles['business'] ?? decoded['business'],
        'id': current?.id ?? decoded['id'],
      });
    } catch (_) {
      return null;
    }
  }

  /// Validates a shell switch server-side. The preference itself stays local.
  Future<bool> switchRole(DairyAppRole role) async {
    final String? userId = await uid();
    if (userId == null) return false;

    final bool isJhatka = role.wire.startsWith('jhatka');
    final DioApiResponse response = await ApiRequestService.makeRequest(
      isJhatka
          ? JhatkaAuthEndpoints.switchRole
          : DairyPartnerEndpoints.switchRole,
      method: 'PATCH',
      token: await authToken(),
      body: <String, dynamic>{'id': userId, 'role': role.wire},
    );
    if (response.errorType != NetErrorType.none) return false;

    try {
      final Map<String, dynamic> decoded =
          jsonDecode(response.body!) as Map<String, dynamic>;
      return decoded['success'] == true;
    } catch (_) {
      return false;
    }
  }

  //// Teardown ////

  Future<bool> refreshAccessToken({
    String? rejectedAccessToken,
    int? expectedSessionVersion,
    String? baseUrl,
    HttpClientAdapter? httpClientAdapter,
  }) {
    final int version = expectedSessionVersion ?? _sessionVersion;
    if (version != _sessionVersion) return Future<bool>.value(false);
    final pending = _refreshInFlight;
    if (pending != null && pending.version == version) return pending.future;

    late final Future<bool> refresh;
    refresh =
        _refreshAccessToken(
          version,
          rejectedAccessToken,
          baseUrl,
          httpClientAdapter,
        ).whenComplete(() {
          if (identical(_refreshInFlight?.future, refresh)) {
            _refreshInFlight = null;
          }
        });
    _refreshInFlight = (version: version, future: refresh);
    return refresh;
  }

  Future<bool> _refreshAccessToken(
    int version,
    String? rejectedAccessToken,
    String? baseUrl,
    HttpClientAdapter? httpClientAdapter,
  ) async {
    try {
      final String? current = AuthTokens.readToken(await authToken());
      if (version != _sessionVersion) return false;
      // A late 401 may belong to a request sent before another call refreshed.
      if (rejectedAccessToken != null &&
          current != null &&
          current != rejectedAccessToken) {
        return true;
      }
      final String? refresh = AuthTokens.readToken(await refreshToken());
      if (version != _sessionVersion) return false;
      if (refresh == null) {
        await clearSession();
        return false;
      }
      final DioApiResponse response = await ApiRequestService.makeRequest(
        PartnerAppEndpoints.refreshToken,
        method: 'POST',
        baseUrl: baseUrl,
        httpClientAdapter: httpClientAdapter,
        body: <String, dynamic>{'refreshToken': refresh},
      );
      if (version != _sessionVersion) return false;
      if (response.errorType != NetErrorType.none) {
        if (response.errorType == NetErrorType.unauthorized ||
            response.errorType == NetErrorType.badRequest) {
          await clearSession();
        }
        return false;
      }
      final AuthTokens? tokens = AuthTokens.tryParse(decodeBody(response));
      // Refresh rotates both credentials. A 200 error envelope is not a session.
      if (tokens == null || tokens.refresh == null) {
        await clearSession();
        return false;
      }
      await _writeSession(() async {
        if (version != _sessionVersion) return;
        await _storeTokens(tokens);
      });
      return version == _sessionVersion;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearSession() async {
    final int version = ++_sessionVersion;
    await _writeSession(() async {
      if (version != _sessionVersion) return;
      await _secure.delete(key: _k.authToken);
      await _secure.delete(key: _k.authRefreshToken);
      final SharedPreferences prefs = await _prefs;
      for (final String key in _k.sessionScoped) {
        await prefs.remove(key);
      }
    });
  }

  Future<void> logout({
    String? baseUrl,
    HttpClientAdapter? httpClientAdapter,
  }) async {
    final int version = _sessionVersion;
    String? refresh;
    try {
      refresh = await refreshToken();
    } catch (_) {
      // A secure-storage read error must not trap the user in a signed-in UI.
    }
    if (version != _sessionVersion) return;
    // Local sign-out must work even when revocation is offline or returns 404.
    await clearSession();
    if (AuthTokens.readToken(refresh) != null) {
      try {
        await ApiRequestService.makeRequest(
          PartnerAppEndpoints.logout,
          method: 'POST',
          baseUrl: baseUrl,
          httpClientAdapter: httpClientAdapter,
          body: <String, dynamic>{'refreshToken': refresh},
        );
      } catch (_) {
        // The local session has already been removed.
      }
    }
  }
}
