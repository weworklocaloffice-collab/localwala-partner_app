/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Â© 2026 WeWorkLocal.
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
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:partner/app/core/config/shared_pref_keys.dart';
import 'package:partner/app/env.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NetErrorType {
  none,
  socket,
  timeout,
  unauthorized,
  badRequest,
  forbidden,
  notFound,
  server,
  cancel,
  badCertificate,
  badResponse,
  unknown,
}

class DioApiResponse {
  final String? body;
  final int? statusCode;
  final NetErrorType errorType;
  final dynamic response;

  const DioApiResponse({
    this.body,
    this.statusCode,
    this.errorType = NetErrorType.none,
    this.response,
  });

  const DioApiResponse.success(this.body)
    : statusCode = 200,
      errorType = NetErrorType.none,
      response = null;

  const DioApiResponse.error(this.errorType, {this.statusCode, this.response})
    : body = null;
}

/// Decoding an API response.
///
/// [DioApiResponse.body] is a `String`, because the Dio instance requests
/// `ResponseType.plain` (see [createDio]). Reading it as a `Map` therefore throws
/// a `TypeError` on every screen rather than failing visibly, which is what the
/// partner screens were doing: `response.body as Map?` on a String.
///
/// This is the one place the shape is turned back into a map, so a screen that
/// forgot to decode fails with a message instead of a cast error.
Map<String, dynamic> decodeBody(DioApiResponse response) {
  final String? raw = response.body;
  if (raw == null || raw.isEmpty) {
    return <String, dynamic>{};
  }

  try {
    final dynamic decoded = jsonDecode(raw);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  } on FormatException {
    return <String, dynamic>{};
  }
}

class ApiRequestService {
  static const int pageSize = 10;
  static const int perPageLimit = 50;

  static const Duration _timeout = Duration(seconds: 30);

  /// Optional transport hook for request tests and nondefault native transports.
  static Dio createDio({
    String? baseUrl,
    String? token,
    String? dairyOutletId,
    HttpClientAdapter? httpClientAdapter,
  }) {
    final Dio dio = Dio();

    dio.options.baseUrl = baseUrl ?? Environments.apiBaseURL;
    dio.options.connectTimeout = _timeout;
    dio.options.receiveTimeout = _timeout;
    dio.options.sendTimeout = _timeout;
    dio.options.responseType = ResponseType.plain;
    dio.options.contentType = Headers.jsonContentType;
    dio.options.headers = <String, dynamic>{
      'Accept': 'application/json',
      'Authorization': token != null && token.isNotEmpty
          ? 'Bearer $token'
          : null,
      if (dairyOutletId != null && dairyOutletId.isNotEmpty)
        'X-Dairy-Outlet-Id': dairyOutletId,
    };
    if (httpClientAdapter != null) dio.httpClientAdapter = httpClientAdapter;

    return dio;
  }

  static Future<DioApiResponse> makeRequest(
    String endpoint, {
    String method = 'POST',
    Map<String, dynamic>? body,
    String? token,
    String? baseUrl,
    bool isMultipart = false,
    HttpClientAdapter? httpClientAdapter,
  }) async {
    final int sessionVersion = AuthRepository.sessionVersion;
    final bool isDairyPartnerRequest = endpoint.contains('v1/dairy/partner/');
    String? dairyOutletId;
    if (isDairyPartnerRequest) {
      try {
        dairyOutletId = (await SharedPreferences.getInstance()).getString(
          SharedPreferencesKey.authKeys.activeDairyOutlet,
        );
      } catch (_) {
        // Unit tests and pre-login requests may not have a preferences plugin.
      }
    }
    final Dio dio = createDio(
      baseUrl: baseUrl,
      token: token,
      dairyOutletId: dairyOutletId,
      httpClientAdapter: httpClientAdapter,
    );
    try {
      final Options options = Options(
        method: method,
        contentType: isMultipart
            ? 'multipart/form-data'
            : Headers.jsonContentType,
        responseType: ResponseType.plain,
      );

      Response<dynamic> response;
      try {
        response = await dio.request<dynamic>(
          endpoint,
          data: body ?? <String, dynamic>{},
          options: options,
        );
      } on DioException catch (e) {
        if (e.response?.statusCode == 401 &&
            token != null &&
            token.isNotEmpty) {
          // Concurrent failures share one refresh; each request retries once.
          final AuthRepository auth = AuthRepository();
          final bool refreshed = await auth.refreshAccessToken(
            rejectedAccessToken: token,
            expectedSessionVersion: sessionVersion,
            baseUrl: baseUrl,
            httpClientAdapter: httpClientAdapter,
          );
          if (refreshed && sessionVersion == AuthRepository.sessionVersion) {
            final String? newToken = await auth.authToken();
            if (newToken == null ||
                sessionVersion != AuthRepository.sessionVersion) {
              rethrow;
            }
            final Dio retryDio = createDio(
              baseUrl: baseUrl,
              token: newToken,
              dairyOutletId: dairyOutletId,
              httpClientAdapter: httpClientAdapter,
            );
            response = await retryDio.request<dynamic>(
              endpoint,
              data: body ?? <String, dynamic>{},
              options: options,
            );
          } else {
            rethrow;
          }
        } else {
          rethrow;
        }
      }

      return DioApiResponse(
        body: response.data.toString(),
        statusCode: response.statusCode,
        errorType: NetErrorType.none,
        response: response,
      );
    } on DioException catch (e) {
      return DioApiResponse.error(
        _mapDioError(e),
        statusCode: e.response?.statusCode,
        response: e.response,
      );
    } on SocketException {
      return const DioApiResponse.error(NetErrorType.socket);
    }
  }

  /// Downloads an authenticated binary response (for example an invoice PDF).
  /// Returns null on any transport/HTTP failure so callers can show a message.
  static Future<Uint8List?> downloadBytes(
    String endpoint, {
    String? token,
    String? baseUrl,
  }) async {
    try {
      final Dio dio = createDio(baseUrl: baseUrl, token: token);
      final Response<dynamic> response = await dio.get<dynamic>(
        endpoint,
        options: Options(responseType: ResponseType.bytes),
      );
      final dynamic data = response.data;
      if (data is Uint8List) return data;
      if (data is List<int>) return Uint8List.fromList(data);
      return null;
    } on DioException {
      return null;
    }
  }

  /// Uploads one file as multipart form data.
  ///
  /// Takes a path, not an `XFile`, so core stays free of image-picker
  /// types — callers in the modules own the picking. The body is built
  /// here because Dio's `FormData` needs the same base URL, timeouts and
  /// bearer header as every other call.
  static Future<DioApiResponse> uploadFile(
    String endpoint, {
    required String filePath,
    required String filename,
    String field = 'fileName',
    Map<String, String>? fields,
    String? token,
    String? baseUrl,
  }) async {
    final Dio dio = createDio(baseUrl: baseUrl, token: token);
    try {
      final FormData form = FormData.fromMap(<String, dynamic>{
        field: await MultipartFile.fromFile(filePath, filename: filename),
        if (fields != null) ...fields,
      });
      final Options options = Options(
        method: 'POST',
        contentType: Headers.multipartFormDataContentType,
        responseType: ResponseType.plain,
      );
      final Response<dynamic> response = await dio.post<dynamic>(
        endpoint,
        data: form,
        options: options,
      );
      return DioApiResponse(
        body: response.data.toString(),
        statusCode: response.statusCode,
        errorType: NetErrorType.none,
        response: response,
      );
    } on DioException catch (e) {
      return DioApiResponse.error(
        _mapDioError(e),
        statusCode: e.response?.statusCode,
        response: e.response,
      );
    } on SocketException {
      return const DioApiResponse.error(NetErrorType.socket);
    }
  }

  static NetErrorType _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return NetErrorType.timeout;
      case DioExceptionType.badCertificate:
        return NetErrorType.badCertificate;
      case DioExceptionType.cancel:
        return NetErrorType.cancel;
      case DioExceptionType.connectionError:
        return NetErrorType.socket;
      case DioExceptionType.badResponse:
        final int? code = e.response?.statusCode;
        if (code == 401) return NetErrorType.unauthorized;
        if (code == 403) return NetErrorType.forbidden;
        if (code == 404) return NetErrorType.notFound;
        if (code != null && code >= 500) return NetErrorType.server;
        if (code != null && code >= 400) return NetErrorType.badRequest;
        return NetErrorType.badResponse;
      case DioExceptionType.unknown:
        return NetErrorType.unknown;
    }
  }
}
