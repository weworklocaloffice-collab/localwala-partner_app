part of 'splash_bloc.dart';

enum SplashStatus { initial, loading, success, failure }

class SplashState {
  final SplashStatus status;
  final bool loggedIn;
  final int statusCode;
  final String alertMessage;

  const SplashState({
    this.status = SplashStatus.initial,
    this.loggedIn = false,
    this.statusCode = 0,
    this.alertMessage = '',
  });

  SplashState copyWith({
    SplashStatus? status,
    bool? loggedIn,
    int? statusCode,
    String? alertMessage,
  }) {
    return SplashState(
      status: status ?? this.status,
      loggedIn: loggedIn ?? this.loggedIn,
      statusCode: statusCode ?? this.statusCode,
      alertMessage: alertMessage ?? this.alertMessage,
    );
  }
}