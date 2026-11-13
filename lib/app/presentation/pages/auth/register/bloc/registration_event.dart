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

abstract class RegistrationEvent {
  const RegistrationEvent();
}

class RegistrationVerticalSelected extends RegistrationEvent {
  final RegistrationVertical vertical;

  const RegistrationVerticalSelected(this.vertical);
}

/// Returns to the vertical picker, discarding the previous OTP.
class RegistrationVerticalCleared extends RegistrationEvent {
  const RegistrationVerticalCleared();
}

class RegistrationFieldChanged extends RegistrationEvent {
  final String? firstName;
  final String? lastName;
  final String? mobile;
  final String? email;
  final String? password;
  final String? confirmPassword;
  final String? inviteCode;

  const RegistrationFieldChanged({
    this.firstName,
    this.lastName,
    this.mobile,
    this.email,
    this.password,
    this.confirmPassword,
    this.inviteCode,
  });
}

class RegistrationBusinessChanged extends RegistrationEvent {
  final String businessName;
  final String businessModel;
  final String requestedBusinessModel;
  final String city;
  final String locality;
  final String fssaiLicence;
  final String fssaiExpiry;
  final String addressLine1;

  // No `ownDeliveryPartner` — every outlet runs its own riders, so there is
  // nothing for the form to state and the API rejects the field if it is sent.

  const RegistrationBusinessChanged({
    required this.businessName,
    this.businessModel = 'direct',
    this.requestedBusinessModel = '',
    this.city = '',
    this.locality = '',
    this.fssaiLicence = '',
    this.fssaiExpiry = '',
    this.addressLine1 = '',
  });
}

/// Loads the city list, then the locality list for whichever city is chosen.
class RegistrationLoadLocations extends RegistrationEvent {
  const RegistrationLoadLocations();
}

/// A city was picked in the outlet form.
///
/// Localities belong to a city, so changing it invalidates any locality already
/// chosen — carrying a stale one forward would submit a pair the server rejects.
class RegistrationCityChanged extends RegistrationEvent {
  final String cityId;

  const RegistrationCityChanged(this.cityId);
}

/// A locality was picked in the outlet form.
class RegistrationLocalityChanged extends RegistrationEvent {
  final String localityId;

  const RegistrationLocalityChanged(this.localityId);
}

class RegistrationSendOtp extends RegistrationEvent {
  const RegistrationSendOtp();
}

/// The six digits typed into the OTP field, kept so the Create account
/// button can verify them even when the field's `onCompleted` has not fired.
class RegistrationOtpChanged extends RegistrationEvent {
  final String otp;

  const RegistrationOtpChanged(this.otp);
}

/// Verifies the SMS OTP with `POST /v1/auth/verifyOTP`.
///
/// Registration itself only accepts an OTP id whose verification has
/// already been marked successful server-side, so this must run before
/// [RegistrationSubmit].
class RegistrationVerifyOtp extends RegistrationEvent {
  final String otp;

  const RegistrationVerifyOtp(this.otp);
}

class RegistrationSubmit extends RegistrationEvent {
  const RegistrationSubmit();
}
