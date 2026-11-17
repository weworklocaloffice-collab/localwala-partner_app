part of 'executive_visit_detail_bloc.dart';

enum ExecutiveVisitDetailStatus { initial, loading, loaded, failure }

class ExecutiveVisitDetailState {
  const ExecutiveVisitDetailState({
    this.status = ExecutiveVisitDetailStatus.initial,
    this.visit,
    this.message = '',
  });

  final ExecutiveVisitDetailStatus status;
  final RealEstateVisitModel? visit;
  final String message;

  ExecutiveVisitDetailState copyWith({
    ExecutiveVisitDetailStatus? status,
    RealEstateVisitModel? visit,
    String? message,
  }) {
    return ExecutiveVisitDetailState(
      status: status ?? this.status,
      visit: visit ?? this.visit,
      message: message ?? this.message,
    );
  }
}
