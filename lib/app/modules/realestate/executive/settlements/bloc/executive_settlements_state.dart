part of 'executive_settlements_bloc.dart';

enum ExecutiveSettlementsStatus { initial, loading, loaded, failure }

class ExecutiveSettlementsState {
  final List<RealEstateSettlementModel> items;
  final int page;
  final int total;
  final ExecutiveSettlementsStatus status;
  final bool loadingMore;
  final String message;

  const ExecutiveSettlementsState({
    this.items = const <RealEstateSettlementModel>[],
    this.page = 1,
    this.total = 0,
    this.status = ExecutiveSettlementsStatus.initial,
    this.loadingMore = false,
    this.message = '',
  });

  bool get hasMore => items.length < total;

  ExecutiveSettlementsState copyWith({
    List<RealEstateSettlementModel>? items,
    int? page,
    int? total,
    ExecutiveSettlementsStatus? status,
    bool? loadingMore,
    String? message,
  }) {
    return ExecutiveSettlementsState(
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      status: status ?? this.status,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message ?? this.message,
    );
  }
}
