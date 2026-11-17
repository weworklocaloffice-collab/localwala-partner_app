part of 'executive_lead_detail_bloc.dart';

enum ExecutiveLeadDetailStatus { initial, loading, loaded, failure }

class ExecutiveLeadDetailState {
  const ExecutiveLeadDetailState({
    this.status = ExecutiveLeadDetailStatus.initial,
    this.detail,
    this.message = '',
  });

  final ExecutiveLeadDetailStatus status;
  final RealEstateLeadDetail? detail;
  final String message;

  ExecutiveLeadDetailState copyWith({
    ExecutiveLeadDetailStatus? status,
    RealEstateLeadDetail? detail,
    String? message,
  }) {
    return ExecutiveLeadDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      message: message ?? this.message,
    );
  }
}
