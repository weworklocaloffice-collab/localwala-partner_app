/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/listing_entitlement.dart';
import 'package:partner/app/modules/realestate/models/listing_package.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'vendor_packages_event.dart';
part 'vendor_packages_state.dart';

/// Remaining listings on one entitlement. Null `totalCount` means
/// unlimited — the -1 sentinel, matching the server's dashboard math.
int entitlementRemaining(RealEstateEntitlementModel entitlement) {
  if (entitlement.totalCount == null) return -1;
  return entitlement.totalCount! - entitlement.consumedCount;
}

/// Aggregate balance across entitlements. Any unlimited package makes the
/// whole balance unlimited (-1) — same rule as `getVendorDashboard`.
int totalRemaining(List<RealEstateEntitlementModel> entitlements) {
  if (entitlements.any((RealEstateEntitlementModel e) => e.totalCount == null)) return -1;
  int sum = 0;
  for (final RealEstateEntitlementModel e in entitlements) {
    sum += e.totalCount! - e.consumedCount;
  }
  return sum;
}

/// The purchase catalogue with the vendor's entitlement balance.
///
/// Buying itself lives in the checkout screen — this is browse + balance.
class VendorPackagesBloc extends Bloc<VendorPackagesEvent, VendorPackagesState> {
  VendorPackagesBloc({RealEstateVendorRepository? repository})
      : _repository = repository ?? RealEstateVendorRepository(),
        super(const VendorPackagesState()) {
    on<VendorPackagesLoadRequested>(_onVendorPackagesLoadRequested);
    on<VendorPackagesRefreshed>(_onVendorPackagesRefreshed);
  }

  final RealEstateVendorRepository _repository;

  Future<void> _load(Emitter<VendorPackagesState> emit) async {
    try {
      final List<dynamic> results = await Future.wait(<Future<dynamic>>[
        _repository.packages(),
        _repository.entitlements(),
      ]);
      emit(state.copyWith(
        status: VendorPackagesStatus.loaded,
        packages: results[0] as List<RealEstatePackageModel>,
        entitlements: results[1] as List<RealEstateEntitlementModel>,
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: VendorPackagesStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: VendorPackagesStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onVendorPackagesLoadRequested(
    VendorPackagesLoadRequested event,
    Emitter<VendorPackagesState> emit,
  ) async {
    emit(state.copyWith(status: VendorPackagesStatus.loading, message: ''));
    await _load(emit);
  }

  Future<void> _onVendorPackagesRefreshed(
    VendorPackagesRefreshed event,
    Emitter<VendorPackagesState> emit,
  ) async {
    emit(state.copyWith(status: VendorPackagesStatus.loading, message: ''));
    await _load(emit);
  }
}
