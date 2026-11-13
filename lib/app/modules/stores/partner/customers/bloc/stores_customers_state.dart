part of 'stores_customers_bloc.dart';

enum StoresCustomersStatus { initial, loading, loaded, failure }

class StoresCustomersState {
  final StoresCustomersStatus status;
  final List<Map<String, dynamic>> rows;
  final String message;

  const StoresCustomersState({
    this.status = StoresCustomersStatus.initial,
    this.rows = const <Map<String, dynamic>>[],
    this.message = '',
  });

  StoresCustomersState copyWith({
    StoresCustomersStatus? status,
    List<Map<String, dynamic>>? rows,
    String? message,
  }) {
    return StoresCustomersState(
      status: status ?? this.status,
      rows: rows ?? this.rows,
      message: message ?? this.message,
    );
  }
}
