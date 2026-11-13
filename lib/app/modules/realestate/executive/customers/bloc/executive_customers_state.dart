/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'executive_customers_bloc.dart';

enum ExecutiveCustomersStatus { initial, loading, loaded, failure }

class ExecutiveCustomersState {
  final List<RealEstateCustomerRef> customers;
  final Map<String, List<RealEstateLeadModel>> leadsByCustomer;
  final ExecutiveCustomersStatus status;
  final String message;

  const ExecutiveCustomersState({
    this.customers = const <RealEstateCustomerRef>[],
    this.leadsByCustomer = const <String, List<RealEstateLeadModel>>{},
    this.status = ExecutiveCustomersStatus.initial,
    this.message = '',
  });

  ExecutiveCustomersState copyWith({
    List<RealEstateCustomerRef>? customers,
    Map<String, List<RealEstateLeadModel>>? leadsByCustomer,
    ExecutiveCustomersStatus? status,
    String? message,
  }) {
    return ExecutiveCustomersState(
      customers: customers ?? this.customers,
      leadsByCustomer: leadsByCustomer ?? this.leadsByCustomer,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}
