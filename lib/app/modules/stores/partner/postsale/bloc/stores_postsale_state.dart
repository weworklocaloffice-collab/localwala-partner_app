part of 'stores_postsale_bloc.dart';

enum StoresPostSaleStatus { initial, loading, loaded, failure }

class StoresPostSaleState {
  final StoresPostSaleStatus status;
  final List<Map<String, dynamic>> rows;
  final String message;

  const StoresPostSaleState({
    this.status = StoresPostSaleStatus.initial,
    this.rows = const <Map<String, dynamic>>[],
    this.message = '',
  });

  StoresPostSaleState copyWith({
    StoresPostSaleStatus? status,
    List<Map<String, dynamic>>? rows,
    String? message,
  }) {
    return StoresPostSaleState(
      status: status ?? this.status,
      rows: rows ?? this.rows,
      message: message ?? this.message,
    );
  }
}
