/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_dashboard_bloc.dart';

enum VendorDashboardStatus { initial, loading, loaded, failure }

class VendorDashboardState {
  final VendorDashboardStatus status;

  /// `GET /vendor/dashboard`: identity, verification, listing and
  /// entitlement counters, `mayPublish`.
  final Map<String, dynamic> summary;

  /// `GET /vendor/analytics`: properties, leads, visits, holds,
  /// liveHolds, sales counts over the vendor's own data.
  final Map<String, dynamic> analytics;

  final String message;

  const VendorDashboardState({
    this.status = VendorDashboardStatus.initial,
    this.summary = const <String, dynamic>{},
    this.analytics = const <String, dynamic>{},
    this.message = '',
  });

  VendorDashboardState copyWith({
    VendorDashboardStatus? status,
    Map<String, dynamic>? summary,
    Map<String, dynamic>? analytics,
    String? message,
  }) {
    return VendorDashboardState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      analytics: analytics ?? this.analytics,
      message: message ?? this.message,
    );
  }
}
