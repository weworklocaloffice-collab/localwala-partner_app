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

import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:partner/app/core/config/api_endpoints.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/models/api_status_response_model.dart';
import 'package:partner/app/core/models/auth_tokens.dart';
import 'package:partner/app/core/models/server_error_model.dart';
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

part 'login_event.dart';
part 'login_state.dart';

enum LoginStatus { initial, loading, otpSent, success, failure }

typedef LoginRequest =
    Future<DioApiResponse> Function(
      String endpoint, {
      String method,
      Map<String, dynamic>? body,
    });

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  LoginBloc({AuthRepository? authRepository, LoginRequest? request})
    : _authRepository = authRepository ?? AuthRepository(),
      _request = request ?? ApiRequestService.makeRequest,
      super(const LoginState()) {
    on<LoginSendOtpEvent>(_onLoginSendOtpEvent);
    on<LoginVerifyOtpEvent>(_onLoginVerifyOtpEvent);
    on<LoginResendOtpEvent>(_onLoginResendOtpEvent);
  }

  final AuthRepository _authRepository;
  final LoginRequest _request;

  /// `POST /v1/auth/partner_app/login_po_verification` â€” sends the SMS and returns
  /// the OTP id. No auth required.
  FutureOr<void> _onLoginSendOtpEvent(
    LoginSendOtpEvent event,
    Emitter<LoginState> emit,
  ) async {
    try {
      emit(state.copyWith(status: LoginStatus.loading, clearOtpId: true));

      final DioApiResponse response = await _request(
        PartnerAppEndpoints.loginOtpVerification,
        method: 'POST',
        body: <String, dynamic>{
          'countryCode': event.countryCode,
          'mobileNumber': int.tryParse(event.mobile) ?? event.mobile,
          'locale': event.locale,
        },
      );

      if (response.errorType != NetErrorType.none) {
        _emitError(emit, response);
        return;
      }

      final Map<String, dynamic>? decoded = _decode(response);
      if (decoded == null) {
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            statusCode: 0,
            alertMessage: 'Unexpected response',
          ),
        );
        return;
      }

      final String? otpId = (decoded['id'] ?? decoded['otpId'])?.toString();
      if (otpId == null || otpId.isEmpty) {
        final ApiStatusResponseModel api = ApiStatusResponseModel.fromJson(
          decoded,
        );
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            statusCode: int.tryParse(decoded['code']?.toString() ?? '0') ?? 0,
            alertMessage: api.message ?? 'OTP could not be sent',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: LoginStatus.otpSent,
          otpId: otpId,
          otpProvider: decoded['provider']?.toString() ?? '',
          alertMessage: '',
        ),
      );
    } catch (e, stacktrace) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          statusCode: 0,
          alertMessage: e.toString(),
        ),
      );
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stacktrace);
    }
  }

  FutureOr<void> _onLoginResendOtpEvent(
    LoginResendOtpEvent event,
    Emitter<LoginState> emit,
  ) async {
    add(
      LoginSendOtpEvent(
        event.mobile,
        countryCode: event.countryCode,
        locale: event.locale,
      ),
    );
  }

  /// `POST /v1/auth/partner_app/login_po/` â€” exchanges the OTP id for tokens.
  ///
  /// The token is persisted here. An earlier revision emitted success without
  /// writing anything, so `isLoggedIn()` stayed false and splash bounced the
  /// user straight back to the login screen.
  FutureOr<void> _onLoginVerifyOtpEvent(
    LoginVerifyOtpEvent event,
    Emitter<LoginState> emit,
  ) async {
    final String otp = event.otp.trim();
    if (otp.length != 6) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          alertMessage: 'Enter the 6 digit OTP',
        ),
      );
      return;
    }

    try {
      emit(state.copyWith(status: LoginStatus.loading, alertMessage: ''));

      // `login_po/` only accepts an OTP whose document is already `status: true`
      // (see verifyWithPhoneOTP on the server), so the verification is a
      // separate, mandatory call.
      final DioApiResponse verification = await _request(
        PartnerAppEndpoints.verifyOtp,
        method: 'POST',
        body: <String, dynamic>{
          'id': event.otpId,
          'provider': state.otpProvider.isNotEmpty ? state.otpProvider : 'app',
          'otp': otp,
        },
      );

      if (verification.errorType != NetErrorType.none) {
        _emitError(emit, verification);
        return;
      }

      final DioApiResponse response = await _request(
        PartnerAppEndpoints.login,
        method: 'POST',
        body: <String, dynamic>{
          'id': event.otpId,
          'locale': event.locale,
          'remember': true,
          'userAgent': event.userAgent,
        },
      );

      if (response.errorType != NetErrorType.none) {
        _emitError(emit, response);
        // `login_po/` consumes the verification before it can fail (for example
        // when the number has no account), so this OTP id cannot be retried;
        // sending a new code is the only way forward.
        emit(state.copyWith(clearOtpId: true));
        return;
      }

      final Map<String, dynamic>? decoded = _decode(response);
      if (decoded == null) {
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            statusCode: 0,
            alertMessage: 'Unexpected response',
          ),
        );
        return;
      }

      final AuthTokens? tokens = AuthTokens.tryParse(decoded);
      if (tokens == null) {
        emit(
          state.copyWith(
            status: LoginStatus.failure,
            statusCode: 0,
            alertMessage: 'Token missing',
          ),
        );
        return;
      }

      await _authRepository.saveTokens(
        accessToken: tokens.access,
        refresh: tokens.refresh,
      );

      final Map<String, dynamic>? profile = decoded['profile'] is Map
          ? Map<String, dynamic>.from(decoded['profile'] as Map)
          : null;
      final Map<String, dynamic>? user = decoded['user'] is Map
          ? Map<String, dynamic>.from(decoded['user'] as Map)
          : null;

      final dynamic rawVerticals = decoded['verticals'];
      final List<dynamic> verticals = rawVerticals is List
          ? rawVerticals
          : <dynamic>[];

      UserSessionModel? session;
      if (profile != null) {
        session = UserSessionModel.fromJson(<String, dynamic>{
          ...profile,
          'verticals': verticals,
        });
      } else if (user != null) {
        // Fall back to the raw user document if the profile block is absent.
        session = UserSessionModel.fromJson(<String, dynamic>{
          ...user,
          'activeRole': user['role'],
          'availableRoles': <String>[user['role'].toString()],
          'verticals': verticals,
        });
      }

      if (session != null) {
        await _authRepository.saveSession(session);
      }

      emit(state.copyWith(status: LoginStatus.success, alertMessage: ''));
    } catch (e, stacktrace) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          statusCode: 0,
          alertMessage: e.toString(),
        ),
      );
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stacktrace);
    }
  }

  Map<String, dynamic>? _decode(DioApiResponse response) {
    if (response.body == null || response.body!.isEmpty) return null;
    try {
      return jsonDecode(response.body!) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  void _emitError(Emitter<LoginState> emit, DioApiResponse response) {
    final Map<String, dynamic>? decoded = _decode(response);
    if (decoded != null) {
      final ServerErrorModel err = ServerErrorModel.fromJson(decoded);
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          statusCode: err.code,
          alertMessage: err.message.isEmpty
              ? response.errorType.name
              : err.message,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: LoginStatus.failure,
        statusCode: 0,
        alertMessage: response.errorType == NetErrorType.socket
            ? 'No internet connection'
            : response.errorType.name,
      ),
    );
  }
}
