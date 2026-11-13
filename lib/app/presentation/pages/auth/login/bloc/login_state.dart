part of 'login_bloc.dart';

class LoginState {
  final LoginStatus status;

  /// Id returned by `login_po_verification` and required by `login_po/`.
  final String? otpId;

  /// Provider recorded with the OTP; `verifyOTP` expects the same value.
  final String otpProvider;

  final int statusCode;
  final String alertMessage;

  const LoginState({
    this.status = LoginStatus.initial,
    this.otpId,
    this.otpProvider = '',
    this.statusCode = 0,
    this.alertMessage = '',
  });

  bool get isBusy => status == LoginStatus.loading;

  bool get canVerify => otpId != null && otpId!.isNotEmpty && !isBusy;

  LoginState copyWith({
    LoginStatus? status,
    String? otpId,
    bool clearOtpId = false,
    String? otpProvider,
    int? statusCode,
    String? alertMessage,
  }) {
    return LoginState(
      status: status ?? this.status,
      otpId: clearOtpId ? null : (otpId ?? this.otpId),
      otpProvider: clearOtpId ? '' : (otpProvider ?? this.otpProvider),
      statusCode: statusCode ?? this.statusCode,
      alertMessage: alertMessage ?? this.alertMessage,
    );
  }
}
