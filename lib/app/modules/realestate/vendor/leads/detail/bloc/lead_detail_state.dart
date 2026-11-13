/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'lead_detail_bloc.dart';

enum LeadDetailStatus { initial, loading, loaded, failure }

class LeadDetailState {
  final LeadDetailStatus status;
  final RealEstateLeadDetail? detail;
  final String message;

  const LeadDetailState({
    this.status = LeadDetailStatus.initial,
    this.detail,
    this.message = '',
  });

  LeadDetailState copyWith({
    LeadDetailStatus? status,
    RealEstateLeadDetail? Function()? detail,
    String? message,
  }) {
    return LeadDetailState(
      status: status ?? this.status,
      detail: detail != null ? detail() : this.detail,
      message: message ?? this.message,
    );
  }
}
