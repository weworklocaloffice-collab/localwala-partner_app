part of 'executive_notifications_bloc.dart';

enum ExecutiveNotificationsStatus { initial, loading, loaded, failure }

class ExecutiveNotificationsState {
  final List<Map<String, dynamic>> items;
  final ExecutiveNotificationsStatus status;
  final String message;

  const ExecutiveNotificationsState({
    this.items = const <Map<String, dynamic>>[],
    this.status = ExecutiveNotificationsStatus.initial,
    this.message = '',
  });

  ExecutiveNotificationsState copyWith({
    List<Map<String, dynamic>>? items,
    ExecutiveNotificationsStatus? status,
    String? message,
  }) {
    return ExecutiveNotificationsState(
      items: items ?? this.items,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}
