part of 'stores_dashboard_bloc.dart';

enum StoresDashboardStatus { initial, loading, loaded, failure }

class StoresDashboardState {
  final StoresDashboardStatus status;
  final Map<String, dynamic> data;
  final String message;

  const StoresDashboardState({
    this.status = StoresDashboardStatus.initial,
    this.data = const <String, dynamic>{},
    this.message = '',
  });

  StoresDashboardState copyWith({
    StoresDashboardStatus? status,
    Map<String, dynamic>? data,
    String? message,
  }) {
    return StoresDashboardState(
      status: status ?? this.status,
      data: data ?? this.data,
      message: message ?? this.message,
    );
  }
}
