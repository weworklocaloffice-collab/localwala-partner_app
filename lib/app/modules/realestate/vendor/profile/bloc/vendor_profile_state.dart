/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_profile_bloc.dart';

enum VendorProfileStatus { initial, loading, loaded, failure }

class VendorProfileState {
  final VendorProfileStatus status;
  final Map<String, dynamic> vendor;
  final String message;

  const VendorProfileState({
    this.status = VendorProfileStatus.initial,
    this.vendor = const <String, dynamic>{},
    this.message = '',
  });

  VendorProfileState copyWith({
    VendorProfileStatus? status,
    Map<String, dynamic>? vendor,
    String? message,
  }) {
    return VendorProfileState(
      status: status ?? this.status,
      vendor: vendor ?? this.vendor,
      message: message ?? this.message,
    );
  }
}
