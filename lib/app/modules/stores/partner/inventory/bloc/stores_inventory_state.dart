part of 'stores_inventory_bloc.dart';

enum StoresInventoryStatus { initial, loading, loaded, failure }

class StoresInventoryState {
  final StoresInventoryStatus status;
  final List<Map<String, dynamic>> rows;
  final bool lowOnly;
  final String message;

  const StoresInventoryState({
    this.status = StoresInventoryStatus.initial,
    this.rows = const <Map<String, dynamic>>[],
    this.lowOnly = false,
    this.message = '',
  });

  StoresInventoryState copyWith({
    StoresInventoryStatus? status,
    List<Map<String, dynamic>>? rows,
    bool? lowOnly,
    String? message,
  }) {
    return StoresInventoryState(
      status: status ?? this.status,
      rows: rows ?? this.rows,
      lowOnly: lowOnly ?? this.lowOnly,
      message: message ?? this.message,
    );
  }
}
