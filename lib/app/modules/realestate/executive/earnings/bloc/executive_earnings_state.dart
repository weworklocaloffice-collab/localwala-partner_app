/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'executive_earnings_bloc.dart';

enum ExecutiveEarningsStatus { initial, loading, loaded, failure }

class ExecutiveEarningsState {
  final ExecutiveEarningsStatus status;
  final RealEstatePage<RealEstateCommissionModel>? commissions;
  final RealEstatePage<RealEstateSettlementModel>? settlements;
  final RealEstatePage<RealEstateLoanModel>? loans;
  final RealEstatePage<RealEstateSaleModel>? sales;
  final String message;

  const ExecutiveEarningsState({
    this.status = ExecutiveEarningsStatus.initial,
    this.commissions,
    this.settlements,
    this.loans,
    this.sales,
    this.message = '',
  });

  ExecutiveEarningsState copyWith({
    ExecutiveEarningsStatus? status,
    RealEstatePage<RealEstateCommissionModel>? commissions,
    RealEstatePage<RealEstateSettlementModel>? settlements,
    RealEstatePage<RealEstateLoanModel>? loans,
    RealEstatePage<RealEstateSaleModel>? sales,
    String? message,
  }) {
    return ExecutiveEarningsState(
      status: status ?? this.status,
      commissions: commissions ?? this.commissions,
      settlements: settlements ?? this.settlements,
      loans: loans ?? this.loans,
      sales: sales ?? this.sales,
      message: message ?? this.message,
    );
  }
}
