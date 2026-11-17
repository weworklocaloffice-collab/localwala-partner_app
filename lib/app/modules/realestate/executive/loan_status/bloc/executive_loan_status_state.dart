part of 'executive_loan_status_bloc.dart';

enum ExecutiveLoanStatusStateStatus { initial, loading, loaded, failure }

class ExecutiveLoanStatusState {
  final List<RealEstateLoanModel> items;
  final int page;
  final int total;
  final ExecutiveLoanStatusStateStatus status;
  final bool loadingMore;
  final String message;

  const ExecutiveLoanStatusState({
    this.items = const <RealEstateLoanModel>[],
    this.page = 1,
    this.total = 0,
    this.status = ExecutiveLoanStatusStateStatus.initial,
    this.loadingMore = false,
    this.message = '',
  });

  bool get hasMore => items.length < total;

  ExecutiveLoanStatusState copyWith({
    List<RealEstateLoanModel>? items,
    int? page,
    int? total,
    ExecutiveLoanStatusStateStatus? status,
    bool? loadingMore,
    String? message,
  }) {
    return ExecutiveLoanStatusState(
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      status: status ?? this.status,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message ?? this.message,
    );
  }
}
