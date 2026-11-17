part of 'executive_holds_bloc.dart';

enum ExecutiveHoldsStatus { initial, loading, loaded, failure }

class ExecutiveHoldsState {
  final List<RealEstateHoldModel> items;
  final int page;
  final int total;
  final ExecutiveHoldsStatus status;
  final bool loadingMore;
  final String message;

  const ExecutiveHoldsState({
    this.items = const <RealEstateHoldModel>[],
    this.page = 1,
    this.total = 0,
    this.status = ExecutiveHoldsStatus.initial,
    this.loadingMore = false,
    this.message = '',
  });

  bool get hasMore => items.length < total;

  ExecutiveHoldsState copyWith({
    List<RealEstateHoldModel>? items,
    int? page,
    int? total,
    ExecutiveHoldsStatus? status,
    bool? loadingMore,
    String? message,
  }) {
    return ExecutiveHoldsState(
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      status: status ?? this.status,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message ?? this.message,
    );
  }
}
