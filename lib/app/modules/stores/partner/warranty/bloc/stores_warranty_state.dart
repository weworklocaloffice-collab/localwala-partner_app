part of 'stores_warranty_bloc.dart';

enum StoresWarrantyStatus { initial, loading, loaded, failure }

class StoresWarrantyState {
  final StoresWarrantyStatus status;
  final List<Map<String, dynamic>> rows;
  final String message;

  const StoresWarrantyState({
    this.status = StoresWarrantyStatus.initial,
    this.rows = const <Map<String, dynamic>>[],
    this.message = '',
  });

  StoresWarrantyState copyWith({
    StoresWarrantyStatus? status,
    List<Map<String, dynamic>>? rows,
    String? message,
  }) {
    return StoresWarrantyState(
      status: status ?? this.status,
      rows: rows ?? this.rows,
      message: message ?? this.message,
    );
  }
}
