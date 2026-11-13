part of 'stores_delivery_bloc.dart';

enum StoresDeliveryStatus { initial, loading, loaded, failure }

class StoresDeliveryState {
  final StoresDeliveryStatus status;
  final List<Map<String, dynamic>> rows;
  final String message;

  const StoresDeliveryState({
    this.status = StoresDeliveryStatus.initial,
    this.rows = const <Map<String, dynamic>>[],
    this.message = '',
  });

  StoresDeliveryState copyWith({
    StoresDeliveryStatus? status,
    List<Map<String, dynamic>>? rows,
    String? message,
  }) {
    return StoresDeliveryState(
      status: status ?? this.status,
      rows: rows ?? this.rows,
      message: message ?? this.message,
    );
  }
}
