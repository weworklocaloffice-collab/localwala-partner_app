/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_packages_bloc.dart';

enum VendorPackagesStatus { initial, loading, loaded, failure }

class VendorPackagesState {
  final VendorPackagesStatus status;
  final List<RealEstatePackageModel> packages;
  final List<RealEstateEntitlementModel> entitlements;
  final String message;

  const VendorPackagesState({
    this.status = VendorPackagesStatus.initial,
    this.packages = const <RealEstatePackageModel>[],
    this.entitlements = const <RealEstateEntitlementModel>[],
    this.message = '',
  });

  VendorPackagesState copyWith({
    VendorPackagesStatus? status,
    List<RealEstatePackageModel>? packages,
    List<RealEstateEntitlementModel>? entitlements,
    String? message,
  }) {
    return VendorPackagesState(
      status: status ?? this.status,
      packages: packages ?? this.packages,
      entitlements: entitlements ?? this.entitlements,
      message: message ?? this.message,
    );
  }
}
