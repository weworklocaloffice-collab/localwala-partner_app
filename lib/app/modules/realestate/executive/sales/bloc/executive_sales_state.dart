part of 'executive_sales_bloc.dart';

enum ExecutiveSalesStatus { initial, loading, loaded, failure }

class ExecutiveSalesState {
  final List<RealEstateSaleModel> items;
  final int page;
  final int total;
  final ExecutiveSalesStatus status;
  final bool loadingMore;
  final String message;

  const ExecutiveSalesState({
    this.items = const <RealEstateSaleModel>[],
    this.page = 1,
    this.total = 0,
    this.status = ExecutiveSalesStatus.initial,
    this.loadingMore = false,
    this.message = '',
  });

  bool get hasMore => items.length < total;

  ExecutiveSalesState copyWith({
    List<RealEstateSaleModel>? items,
    int? page,
    int? total,
    ExecutiveSalesStatus? status,
    bool? loadingMore,
    String? message,
  }) {
    return ExecutiveSalesState(
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      status: status ?? this.status,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message ?? this.message,
    );
  }
}
