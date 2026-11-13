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

part of 'registration_bloc.dart';

enum RegistrationStatus { initial, verticalSelected, otpSent, success, failure }

/// A city or locality in the outlet form's dropdowns.
///
/// The API returns different shapes for the two — the city list carries
/// `location`, the locality list carries `city` — so both are reduced to the
/// only two things the dropdown needs.
class LocationOption {
  const LocationOption({required this.id, required this.name});

  final String id;
  final String name;
}

class RegistrationState {
  final RegistrationStatus status;
  final RegistrationVertical? vertical;

  final String firstName;
  final String lastName;
  final String mobile;
  final String email;

  /// Required by the API and by `User`. The OTP proves the phone; this proves
  /// the account can be logged into again without the phone.
  final String password;
  final String confirmPassword;
  final String inviteCode;

  final String businessName;
  final String businessModel;
  final String requestedBusinessModel;

  // No `ownDeliveryPartner`. It used to ask whether this outlet runs its own riders
  // or leaves delivery to the platform pool. There is no platform pool in dairy, so
  // the question had no "no" — and the API now rejects the field outright rather
  // than ignoring it, so keeping it would have failed every registration.

  /// Outlet location, as ids. Names live in [cityOptions]/[localityOptions];
  /// only the chosen ids are sent, because the server re-validates the pairing
  /// and a name would be meaningless to it.
  final String city;
  final String locality;
  final String fssaiLicence;
  final String fssaiExpiry;
  final String addressLine1;

  /// Dropdown sources, fetched as the form opens and as the city changes.
  final List<LocationOption> cityOptions;
  final List<LocationOption> localityOptions;
  final bool loadingLocations;

  final String? otpId;

  /// Provider string returned by `send_otp`, required by `verifyOTP`.
  final String otpProvider;

  /// Latest digits entered in the OTP field.
  final String otpCode;

  /// A verification call is in flight.
  final bool otpVerifying;

  /// `verifyOTP` has marked this OTP id as verified server-side.
  final bool otpVerified;

  /// The registration request is in flight.
  final bool submitting;

  final int statusCode;
  final String alertMessage;

  const RegistrationState({
    this.status = RegistrationStatus.initial,
    this.vertical,
    this.firstName = '',
    this.lastName = '',
    this.mobile = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.inviteCode = '',
    this.businessName = '',
    this.businessModel = 'direct',
    this.requestedBusinessModel = '',
    this.city = '',
    this.locality = '',
    this.fssaiLicence = '',
    this.fssaiExpiry = '',
    this.addressLine1 = '',
    this.cityOptions = const <LocationOption>[],
    this.localityOptions = const <LocationOption>[],
    this.loadingLocations = false,
    this.otpId,
    this.otpProvider = '',
    this.otpCode = '',
    this.otpVerifying = false,
    this.otpVerified = false,
    this.submitting = false,
    this.statusCode = 0,
    this.alertMessage = '',
  });

  bool get needsBusinessDetails => vertical?.needsBusinessDetails ?? false;

  bool get isJhatka => vertical == RegistrationVertical.jhatka;

  bool get isDairy => vertical == RegistrationVertical.dairy;

  bool get isStores => vertical == RegistrationVertical.stores;

  bool get isDriver => vertical?.isDriver ?? false;

  bool get isBusy =>
      status == RegistrationStatus.otpSent ||
      status == RegistrationStatus.success;

  /// OTP can only be requested once a vertical is picked and a mobile looks sane.
  bool get canSendOtp =>
      vertical != null &&
      mobile.length == 10 &&
      status != RegistrationStatus.otpSent;

  /// A six-digit code is present and no verification call is in flight.
  bool get canVerifyOtp =>
      otpId != null && otpCode.length == 6 && !otpVerifying && !submitting;

  /// Whether the password meets the API's rule: 8+ characters with at least one
  /// letter and one number. Checked here so the submit button is disabled rather
  /// than failing server-side.
  bool get isPasswordAcceptable =>
      password.length >= 8 &&
      password.contains(RegExp('[a-zA-Z]')) &&
      password.contains(RegExp('[0-9]'));

  bool get needsOutletLocation => needsBusinessDetails;

  /// Everything the API requires before an account can be created.
  bool get canSubmit {
    final bool basics =
        firstName.trim().isNotEmpty &&
        lastName.trim().isNotEmpty &&
        mobile.length == 10 &&
        email.trim().isNotEmpty &&
        isPasswordAcceptable &&
        password == confirmPassword;

    if (!basics) return false;
    if (isDriver) return inviteCode.trim().length == 48;
    if (!needsOutletLocation) return true;

    final bool location = city.isNotEmpty && locality.isNotEmpty;
    if (isDairy && !<String>{'franchise', 'commission_partner'}.contains(requestedBusinessModel)) {
      return false;
    }
    if (isJhatka) {
      final bool licence = fssaiLicence.trim().isNotEmpty;
      final bool expiry = fssaiExpiry.trim().isNotEmpty;
      return location && addressLine1.trim().isNotEmpty && licence == expiry;
    }
    return location;
  }

  RegistrationState copyWith({
    RegistrationStatus? status,
    RegistrationVertical? vertical,
    String? firstName,
    String? lastName,
    String? mobile,
    String? email,
    String? password,
    String? confirmPassword,
    String? inviteCode,
    String? businessName,
    String? businessModel,
    String? requestedBusinessModel,
    String? city,
    String? locality,
    String? fssaiLicence,
    String? fssaiExpiry,
    String? addressLine1,
    List<LocationOption>? cityOptions,
    List<LocationOption>? localityOptions,
    bool? loadingLocations,
    String? otpId,
    bool clearOtpId = false,
    String? otpProvider,
    String? otpCode,
    bool? otpVerifying,
    bool? otpVerified,
    bool? submitting,
    int? statusCode,
    String? alertMessage,
  }) {
    return RegistrationState(
      status: status ?? this.status,
      vertical: vertical ?? this.vertical,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mobile: mobile ?? this.mobile,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      inviteCode: inviteCode ?? this.inviteCode,
      businessName: businessName ?? this.businessName,
      businessModel: businessModel ?? this.businessModel,
      requestedBusinessModel: requestedBusinessModel ?? this.requestedBusinessModel,
      city: city ?? this.city,
      locality: locality ?? this.locality,
      cityOptions: cityOptions ?? this.cityOptions,
      localityOptions: localityOptions ?? this.localityOptions,
      loadingLocations: loadingLocations ?? this.loadingLocations,
      fssaiLicence: fssaiLicence ?? this.fssaiLicence,
      fssaiExpiry: fssaiExpiry ?? this.fssaiExpiry,
      addressLine1: addressLine1 ?? this.addressLine1,
      otpId: clearOtpId ? null : (otpId ?? this.otpId),
      otpProvider: clearOtpId ? '' : (otpProvider ?? this.otpProvider),
      otpCode: clearOtpId ? '' : (otpCode ?? this.otpCode),
      otpVerifying: otpVerifying ?? this.otpVerifying,
      otpVerified: clearOtpId ? false : (otpVerified ?? this.otpVerified),
      submitting: submitting ?? this.submitting,
      statusCode: statusCode ?? this.statusCode,
      alertMessage: alertMessage ?? this.alertMessage,
    );
  }
}
