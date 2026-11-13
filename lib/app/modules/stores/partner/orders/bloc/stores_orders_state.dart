part of 'stores_orders_bloc.dart';

enum StoresOrdersStatus { initial, loading, loaded, failure }

class StoresOrdersState {
  final StoresOrdersStatus status;
  final List<Map<String, dynamic>> orders;
  final String? lifecycle;
  final String message;

  const StoresOrdersState({
    this.status = StoresOrdersStatus.initial,
    this.orders = const <Map<String, dynamic>>[],
    this.lifecycle,
    this.message = '',
  });

  StoresOrdersState copyWith({
    StoresOrdersStatus? status,
    List<Map<String, dynamic>>? orders,
    String? lifecycle,
    String? message,
  }) {
    return StoresOrdersState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      lifecycle: lifecycle ?? this.lifecycle,
      message: message ?? this.message,
    );
  }
}
