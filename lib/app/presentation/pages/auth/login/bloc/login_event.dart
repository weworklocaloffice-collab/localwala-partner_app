part of 'login_bloc.dart';

abstract class LoginEvent {
  const LoginEvent();
}

/// Asks the API to SMS an OTP. `otpId` comes back in the response and must be
/// supplied to [LoginVerifyOtpEvent].
class LoginSendOtpEvent extends LoginEvent {
  final String mobile;
  final String countryCode;
  final String locale;

  const LoginSendOtpEvent(
    this.mobile, {
    this.countryCode = '+91',
    this.locale = 'en',
  });
}

class LoginResendOtpEvent extends LoginEvent {
  final String mobile;
  final String countryCode;
  final String locale;

  const LoginResendOtpEvent(
    this.mobile, {
    this.countryCode = '+91',
    this.locale = 'en',
  });
}

class LoginVerifyOtpEvent extends LoginEvent {
  final String otpId;
  final String otp;
  final String locale;
  final String? userAgent;

  const LoginVerifyOtpEvent(
    this.otpId,
    this.otp, {
    this.locale = 'en',
    this.userAgent,
  });
}
