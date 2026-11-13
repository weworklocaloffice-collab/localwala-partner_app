/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_commissions_bloc.dart';

enum VendorCommissionsStatus { initial, loading, loaded, failure }

class VendorCommissionsState {
  final VendorCommissionsStatus status;
  final List<RealEstateCommissionModel> commissions;
  final int total;
  final String filter;
  final String message;

  const VendorCommissionsState({
    this.status = VendorCommissionsStatus.initial,
    this.commissions = const <RealEstateCommissionModel>[],
    this.total = 0,
    this.filter = '',
    this.message = '',
  });

  VendorCommissionsState copyWith({
    VendorCommissionsStatus? status,
    List<RealEstateCommissionModel>? commissions,
    int? total,
    String? filter,
    String? message,
  }) {
    return VendorCommissionsState(
      status: status ?? this.status,
      commissions: commissions ?? this.commissions,
      total: total ?? this.total,
      filter: filter ?? this.filter,
      message: message ?? this.message,
    );
  }
}
