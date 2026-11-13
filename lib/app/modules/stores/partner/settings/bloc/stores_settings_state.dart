part of 'stores_settings_bloc.dart';

enum StoresSettingsStatus { initial, loading, loaded, failure }

class StoresSettingsState {
  final StoresSettingsStatus status;
  final Map<String, dynamic> outlet;
  final String message;

  const StoresSettingsState({
    this.status = StoresSettingsStatus.initial,
    this.outlet = const <String, dynamic>{},
    this.message = '',
  });

  StoresSettingsState copyWith({
    StoresSettingsStatus? status,
    Map<String, dynamic>? outlet,
    String? message,
  }) {
    return StoresSettingsState(
      status: status ?? this.status,
      outlet: outlet ?? this.outlet,
      message: message ?? this.message,
    );
  }
}
