part of 'stores_exchanges_bloc.dart';

enum StoresExchangesStatus { initial, loading, loaded, failure }

class StoresExchangesState {
  final StoresExchangesStatus status;
  final List<Map<String, dynamic>> rows;
  final String message;

  const StoresExchangesState({
    this.status = StoresExchangesStatus.initial,
    this.rows = const <Map<String, dynamic>>[],
    this.message = '',
  });

  StoresExchangesState copyWith({
    StoresExchangesStatus? status,
    List<Map<String, dynamic>>? rows,
    String? message,
  }) {
    return StoresExchangesState(
      status: status ?? this.status,
      rows: rows ?? this.rows,
      message: message ?? this.message,
    );
  }
}
