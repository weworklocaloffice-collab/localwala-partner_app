part of 'executive_customer_detail_bloc.dart';

enum ExecutiveCustomerDetailStatus { initial, loading, loaded, failure }

class ExecutiveCustomerDetailState {
  const ExecutiveCustomerDetailState({
    this.status = ExecutiveCustomerDetailStatus.initial,
    this.customerId = '',
    this.leads = const <RealEstateLeadModel>[],
    this.message = '',
  });

  final ExecutiveCustomerDetailStatus status;
  final String customerId;
  final List<RealEstateLeadModel> leads;
  final String message;

  ExecutiveCustomerDetailState copyWith({
    ExecutiveCustomerDetailStatus? status,
    String? customerId,
    List<RealEstateLeadModel>? leads,
    String? message,
  }) {
    return ExecutiveCustomerDetailState(
      status: status ?? this.status,
      customerId: customerId ?? this.customerId,
      leads: leads ?? this.leads,
      message: message ?? this.message,
    );
  }
}
