/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_analytics_bloc.dart';

enum VendorAnalyticsStatus { initial, loading, loaded, failure }

class VendorAnalyticsState {
  final VendorAnalyticsStatus status;
  final Map<String, dynamic> data;
  final String message;

  const VendorAnalyticsState({
    this.status = VendorAnalyticsStatus.initial,
    this.data = const <String, dynamic>{},
    this.message = '',
  });

  VendorAnalyticsState copyWith({
    VendorAnalyticsStatus? status,
    Map<String, dynamic>? data,
    String? message,
  }) {
    return VendorAnalyticsState(
      status: status ?? this.status,
      data: data ?? this.data,
      message: message ?? this.message,
    );
  }
}
