part of 'stores_returns_bloc.dart';

enum StoresReturnsStatus { initial, loading, loaded, failure }

class StoresReturnsState {
  final StoresReturnsStatus status;
  final List<Map<String, dynamic>> rows;
  final String message;

  const StoresReturnsState({
    this.status = StoresReturnsStatus.initial,
    this.rows = const <Map<String, dynamic>>[],
    this.message = '',
  });

  StoresReturnsState copyWith({
    StoresReturnsStatus? status,
    List<Map<String, dynamic>>? rows,
    String? message,
  }) {
    return StoresReturnsState(
      status: status ?? this.status,
      rows: rows ?? this.rows,
      message: message ?? this.message,
    );
  }
}
