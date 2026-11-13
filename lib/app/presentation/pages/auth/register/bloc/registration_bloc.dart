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
import 'package:partner/app/core/models/server_error_model.dart';
import 'package:partner/app/core/models/auth_tokens.dart';
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

part 'registration_event.dart';
part 'registration_state.dart';
part 'registration_vertical.dart';

typedef RegistrationRequest =
    Future<DioApiResponse> Function(
      String endpoint, {
      String method,
      Map<String, dynamic>? body,
    });

/// Self-registration for the app's supported partner verticals.
///
/// Dairy and Jhatka partners are recruited in the field and create their own
/// account from the app. Both use the same form; only the endpoint and the
/// address field differ. The server-side allowlist remains authoritative.
class RegistrationBloc extends Bloc<RegistrationEvent, RegistrationState> {
  RegistrationBloc({
    AuthRepository? authRepository,
    RegistrationRequest? request,
  }) : _authRepository = authRepository ?? AuthRepository(),
       _request = request ?? ApiRequestService.makeRequest,
       super(const RegistrationState()) {
    on<RegistrationVerticalSelected>(_onVerticalSelected);
    on<RegistrationVerticalCleared>(_onVerticalCleared);
    on<RegistrationFieldChanged>(_onFieldChanged);
    on<RegistrationBusinessChanged>(_onBusinessChanged);
    on<RegistrationLoadLocations>(_onLoadLocations);
    on<RegistrationCityChanged>(_onCityChanged);
    on<RegistrationLocalityChanged>(_onLocalityChanged);
    on<RegistrationSendOtp>(_onSendOtp);
    on<RegistrationOtpChanged>(_onOtpChanged);
    on<RegistrationVerifyOtp>(_onVerifyOtp);
    on<RegistrationSubmit>(_onSubmit);
  }

  final AuthRepository _authRepository;
  final RegistrationRequest _request;

  /// Cities for the outlet form's first dropdown.
  ///
  /// Public, because the form is filled before the phone is verified. Only
  /// `id` and `name` are kept â€” the server re-validates the city/locality pairing
  /// on submit, so nothing else from the response is trusted or needed.
  Future<List<LocationOption>> _fetchCities() async {
    final DioApiResponse response = await _request(
      state.isJhatka
          ? JhatkaAuthEndpoints.registerCities
          : DairyPartnerEndpoints.registerCities,
      method: 'GET',
    );

    if (response.errorType != NetErrorType.none) {
      return <LocationOption>[];
    }

    final dynamic decoded = _decodeAny(response);
    if (decoded is! List) return <LocationOption>[];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(
          (Map<String, dynamic> row) => LocationOption(
            id: (row['id'] ?? row['_id'] ?? '').toString(),
            name: (row['name'] ?? '').toString(),
          ),
        )
        .where((LocationOption option) => option.id.isNotEmpty)
        .toList();
  }

  /// Localities within the chosen city.
  Future<List<LocationOption>> _fetchLocalities(String cityId) async {
    if (cityId.isEmpty) return <LocationOption>[];

    final String endpoint = state.isJhatka
        ? JhatkaAuthEndpoints.localitiesFromCity
        : DairyPartnerEndpoints.localitiesFromCity;
    final DioApiResponse response = await _request(
      endpoint.replaceAll('{city}', cityId),
      method: 'GET',
    );

    if (response.errorType != NetErrorType.none) {
      return <LocationOption>[];
    }

    final dynamic decoded = _decodeAny(response);
    // The endpoint answers `{ localities: [...] }`, unlike the bare city array.
    final dynamic rows = decoded is Map ? decoded['localities'] : decoded;
    if (rows is! List) return <LocationOption>[];

    return rows
        .whereType<Map<String, dynamic>>()
        .map(
          (Map<String, dynamic> row) => LocationOption(
            id: (row['id'] ?? row['_id'] ?? '').toString(),
            name: (row['name'] ?? '').toString(),
          ),
        )
        .where((LocationOption option) => option.id.isNotEmpty)
        .toList();
  }

  FutureOr<void> _onLoadLocations(
    RegistrationLoadLocations event,
    Emitter<RegistrationState> emit,
  ) async {
    if (state.cityOptions.isNotEmpty) {
      return;
    }
    emit(state.copyWith(loadingLocations: true));
    final List<LocationOption> cities = await _fetchCities();
    emit(state.copyWith(cityOptions: cities, loadingLocations: false));
  }

  FutureOr<void> _onCityChanged(
    RegistrationCityChanged event,
    Emitter<RegistrationState> emit,
  ) async {
    if (event.cityId == state.city) return;

    // The locality is cleared alongside the city: they are a pair, and carrying a
    // locality from the previous city forward would submit a combination the
    // server rejects with a message about the two not matching.
    emit(
      state.copyWith(
        city: event.cityId,
        locality: '',
        localityOptions: const <LocationOption>[],
        loadingLocations: true,
        status: state.status == RegistrationStatus.otpSent
            ? RegistrationStatus.verticalSelected
            : state.status,
        clearOtpId: true,
      ),
    );

    final List<LocationOption> localities = await _fetchLocalities(
      event.cityId,
    );
    emit(state.copyWith(localityOptions: localities, loadingLocations: false));
  }

  void _onLocalityChanged(
    RegistrationLocalityChanged event,
    Emitter<RegistrationState> emit,
  ) {
    if (event.localityId == state.locality) return;
    emit(
      state.copyWith(
        locality: event.localityId,
        status: state.status == RegistrationStatus.otpSent
            ? RegistrationStatus.verticalSelected
            : state.status,
        clearOtpId: true,
      ),
    );
  }

  void _onVerticalSelected(
    RegistrationVerticalSelected event,
    Emitter<RegistrationState> emit,
  ) {
    emit(
      state.copyWith(
        status: RegistrationStatus.verticalSelected,
        vertical: event.vertical,
        clearOtpId: true,
        alertMessage: '',
      ),
    );

    // Both outlet-registration roles have these dropdowns, so the list is
    // fetched on demand rather than on every vertical pick.
    if (event.vertical.needsBusinessDetails) {
      add(const RegistrationLoadLocations());
    }
  }

  /// Back to the vertical picker. The form is intentionally not cleared so a
  /// mis-tap does not destroy typed input; `otpId` is dropped because it belongs
  /// to the abandoned vertical's verification.
  void _onVerticalCleared(
    RegistrationVerticalCleared event,
    Emitter<RegistrationState> emit,
  ) {
    emit(
      RegistrationState(
        firstName: state.firstName,
        lastName: state.lastName,
        mobile: state.mobile,
        email: state.email,
        password: state.password,
        confirmPassword: state.confirmPassword,
        inviteCode: state.inviteCode,
      ),
    );
  }

  void _onFieldChanged(
    RegistrationFieldChanged event,
    Emitter<RegistrationState> emit,
  ) {
    emit(
      state.copyWith(
        firstName: event.firstName,
        lastName: event.lastName,
        mobile: event.mobile,
        email: event.email,
        password: event.password,
        confirmPassword: event.confirmPassword,
        inviteCode: event.inviteCode,
        // Any form change invalidates the sent OTP, since it was issued for the
        // values that were on screen at the time. The status has to move out of
        // `otpSent` too, or the form would show neither the OTP field (its id is
        // cleared) nor an enabled Send OTP button.
        status: state.status == RegistrationStatus.otpSent
            ? RegistrationStatus.verticalSelected
            : state.status,
        clearOtpId: true,
      ),
    );
  }

  void _onBusinessChanged(
    RegistrationBusinessChanged event,
    Emitter<RegistrationState> emit,
  ) {
    emit(
      state.copyWith(
        businessName: event.businessName,
        businessModel: event.businessModel,
        requestedBusinessModel: event.requestedBusinessModel,
        city: event.city,
        locality: event.locality,
        fssaiLicence: event.fssaiLicence,
        fssaiExpiry: event.fssaiExpiry,
        addressLine1: event.addressLine1,
      ),
    );
  }

  FutureOr<void> _onSendOtp(
    RegistrationSendOtp event,
    Emitter<RegistrationState> emit,
  ) async {
    final RegistrationVertical? vertical = state.vertical;
    if (vertical == null || state.mobile.length != 10) {
      emit(
        state.copyWith(
          status: RegistrationStatus.failure,
          alertMessage: 'Select a vertical and enter a 10 digit mobile',
        ),
      );
      return;
    }

    try {
      final DioApiResponse response = await _request(
        vertical.sendOtpEndpoint,
        method: 'POST',
        body: <String, dynamic>{
          'countryCode': '+91',
          'mobileNumber': int.tryParse(state.mobile) ?? state.mobile,
          if (vertical.role != null) 'role': vertical.role,
          'locale': 'en',
        },
      );

      final Map<String, dynamic>? decoded = _decode(response);
      if (response.errorType != NetErrorType.none || decoded == null) {
        _emitError(emit, response);
        return;
      }

      final String? otpId = (decoded['id'] ?? decoded['otpId'])?.toString();
      if (otpId == null || otpId.isEmpty) {
        emit(
          state.copyWith(
            status: RegistrationStatus.failure,
            alertMessage:
                decoded['message']?.toString() ?? 'OTP could not be sent',
          ),
        );
        return;
      }

      emit(
        state.copyWith(
          status: RegistrationStatus.otpSent,
          otpId: otpId,
          otpProvider: decoded['provider']?.toString() ?? '',
          otpCode: '',
          otpVerifying: false,
          otpVerified: false,
          alertMessage: '',
        ),
      );
    } catch (e, stacktrace) {
      emit(
        state.copyWith(
          status: RegistrationStatus.failure,
          alertMessage: e.toString(),
        ),
      );
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stacktrace);
    }
  }

  void _onOtpChanged(
    RegistrationOtpChanged event,
    Emitter<RegistrationState> emit,
  ) {
    emit(state.copyWith(otpCode: event.otp.trim()));
  }

  /// Marks the OTP verified server-side, then submits the registration.
  ///
  /// `POST /v1/auth/verifyOTP` is what flips the OTP document to `status: true`;
  /// both registration endpoints reject an id that has not been through it with
  /// "Verification failed", so this cannot be skipped.
  FutureOr<void> _onVerifyOtp(
    RegistrationVerifyOtp event,
    Emitter<RegistrationState> emit,
  ) async {
    // The code is already verified server-side; `verifyOTP` refuses to run
    // twice for the same id, so a retry has to be the registration itself.
    if (state.otpVerified) {
      add(const RegistrationSubmit());
      return;
    }

    final String? otpId = state.otpId;
    if (otpId == null || otpId.isEmpty) {
      emit(
        state.copyWith(
          status: RegistrationStatus.failure,
          alertMessage: 'Request an OTP first',
        ),
      );
      return;
    }

    final String otp = event.otp.trim();
    if (otp.length != 6) {
      emit(
        state.copyWith(
          status: RegistrationStatus.failure,
          alertMessage: 'Enter the 6 digit OTP',
        ),
      );
      return;
    }

    if (state.otpVerifying) return;

    emit(state.copyWith(otpVerifying: true, otpCode: otp, alertMessage: ''));

    try {
      final DioApiResponse response = await _request(
        PartnerAppEndpoints.verifyOtp,
        method: 'POST',
        body: <String, dynamic>{
          'id': otpId,
          'provider': state.otpProvider.isNotEmpty ? state.otpProvider : 'app',
          'otp': otp,
        },
      );

      if (response.errorType != NetErrorType.none) {
        _emitError(emit, response);
        return;
      }

      emit(
        state.copyWith(
          otpVerifying: false,
          otpVerified: true,
          alertMessage: '',
        ),
      );

      // The field's `onCompleted` is the normal trigger; submitting here keeps
      // the Create account button working for a code entered by paste/tap.
      add(const RegistrationSubmit());
    } catch (e, stacktrace) {
      emit(
        state.copyWith(
          status: RegistrationStatus.failure,
          otpVerifying: false,
          alertMessage: e.toString(),
        ),
      );
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stacktrace);
    }
  }

  /// Submits the registration. On success the session is persisted exactly as in
  /// login, so the role gate has a session to resolve.
  FutureOr<void> _onSubmit(
    RegistrationSubmit event,
    Emitter<RegistrationState> emit,
  ) async {
    if (state.submitting) return;

    final RegistrationVertical? vertical = state.vertical;
    final String? otpId = state.otpId;
    if (vertical == null || otpId == null || !state.otpVerified) {
      emit(
        state.copyWith(
          status: RegistrationStatus.failure,
          alertMessage: 'Verify your mobile first',
        ),
      );
      return;
    }

    // Checked here as well as in the form: a submitted form can reach this with
    // an unacceptable password if the field was pasted into after the button was
    // enabled, and the API's error for it is less specific than this one.
    if (!state.isPasswordAcceptable) {
      emit(
        state.copyWith(
          status: RegistrationStatus.failure,
          alertMessage:
              'Password must be at least 8 characters, with a letter and a number',
        ),
      );
      return;
    }

    if (state.password != state.confirmPassword) {
      emit(
        state.copyWith(
          status: RegistrationStatus.failure,
          alertMessage: 'The two passwords do not match',
        ),
      );
      return;
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      'id': otpId,
      'locale': 'en',
      'remember': true,
      'userAgent': 'partner_app',
      'firstName': state.firstName.trim(),
      'lastName': state.lastName.trim(),
      'countryCode': '+91',
      'mobile': int.tryParse(state.mobile) ?? state.mobile,
      'email': state.email.trim(),
      'password': state.password,
      if (vertical.role != null) 'role': vertical.role,
      if (vertical.isDriver) 'inviteCode': state.inviteCode.trim().toLowerCase(),
    };

    if (state.needsBusinessDetails) {
      payload.addAll(<String, dynamic>{
        'businessName': state.businessName.trim(),
        if (state.isDairy) 'requestedBusinessModel': state.requestedBusinessModel,
        if (state.isJhatka) 'businessModel': state.businessModel,
        // No `ownDeliveryPartner`. Every outlet runs its own riders.
        //
        // City and locality are required by both APIs; `canSubmit` already
        // refuses to get here without them.
        'city': state.city,
        'locality': state.locality,
        if (state.isJhatka) 'addressLine1': state.addressLine1.trim(),
        if (state.isJhatka && state.fssaiLicence.trim().isNotEmpty)
          'fssaiLicence': state.fssaiLicence.trim(),
        if (state.isJhatka && state.fssaiExpiry.trim().isNotEmpty)
          'fssaiExpiry': state.fssaiExpiry.trim(),
      });
    }

    emit(state.copyWith(submitting: true, alertMessage: ''));
    try {
      final DioApiResponse response = await _request(
        vertical.registerEndpoint,
        method: 'POST',
        body: payload,
      );

      final Map<String, dynamic>? decoded = _decode(response);
      if (response.errorType != NetErrorType.none || decoded == null) {
        _emitError(emit, response);
        return;
      }

      final AuthTokens? tokens = AuthTokens.tryParse(decoded);
      if (tokens == null) {
        emit(
          state.copyWith(
            status: RegistrationStatus.failure,
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
      if (profile != null) {
        await _authRepository.saveSession(
          UserSessionModel.fromJson(<String, dynamic>{
            ...profile,
            'verticals': verticals,
            'activeVertical': vertical.key,
          }),
        );
      } else if (user != null) {
        await _authRepository.saveSession(
          UserSessionModel.fromJson(<String, dynamic>{
            ...user,
            'activeRole': user['role'],
            'availableRoles': <String>[user['role'].toString()],
            'verticals': verticals,
            'activeVertical': vertical.key,
          }),
        );
      }

      emit(
        state.copyWith(status: RegistrationStatus.success, alertMessage: ''),
      );
    } catch (e, stacktrace) {
      emit(
        state.copyWith(
          status: RegistrationStatus.failure,
          alertMessage: e.toString(),
        ),
      );
      if (!kIsWeb) FirebaseCrashlytics.instance.recordError(e, stacktrace);
    } finally {
      emit(state.copyWith(submitting: false));
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

  /// Decodes without assuming a shape.
  ///
  /// The location endpoints disagree: cities answer with a bare array while
  /// localities answer `{ localities: [...] }`. `_decode` casts to a Map and
  /// would return null for the city list, so this one is used for both and the
  /// caller handles the two envelopes.
  dynamic _decodeAny(DioApiResponse response) {
    if (response.body == null || response.body!.isEmpty) return null;
    try {
      return jsonDecode(response.body!);
    } catch (_) {
      return null;
    }
  }

  void _emitError(Emitter<RegistrationState> emit, DioApiResponse response) {
    final Map<String, dynamic>? decoded = _decode(response);
    if (decoded != null) {
      final ServerErrorModel err = ServerErrorModel.fromJson(decoded);
      emit(
        state.copyWith(
          status: RegistrationStatus.failure,
          statusCode: err.code,
          otpVerifying: false,
          alertMessage: err.message.isEmpty
              ? response.errorType.name
              : err.message,
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: RegistrationStatus.failure,
        otpVerifying: false,
        alertMessage: response.errorType == NetErrorType.socket
            ? 'No internet connection'
            : response.errorType.name,
      ),
    );
  }
}
