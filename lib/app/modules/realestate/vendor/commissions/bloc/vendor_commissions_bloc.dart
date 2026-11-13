/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/commission.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'vendor_commissions_event.dart';
part 'vendor_commissions_state.dart';

/// Sale commissions (plan §11.3, §1.1).
///
/// Sales commission ONLY — never mixed with package spend. The server
/// scopes rows to this vendor; the app only filters by status.
class VendorCommissionsBloc extends Bloc<VendorCommissionsEvent, VendorCommissionsState> {
  VendorCommissionsBloc({RealEstateVendorRepository? repository})
      : _repository = repository ?? RealEstateVendorRepository(),
        super(const VendorCommissionsState()) {
    on<VendorCommissionsLoadRequested>(_onLoadRequested);
    on<VendorCommissionsRefreshed>(_onRefreshed);
    on<VendorCommissionsFilterChanged>(_onFilterChanged);
  }

  final RealEstateVendorRepository _repository;

  Future<void> _load(Emitter<VendorCommissionsState> emit) async {
    try {
      final RealEstatePage<RealEstateCommissionModel> page = await _repository.commissions(
        limit: 20,
        status: state.filter.isEmpty ? null : state.filter,
      );
      emit(state.copyWith(
        status: VendorCommissionsStatus.loaded,
        commissions: page.items,
        total: page.total,
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: VendorCommissionsStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: VendorCommissionsStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onLoadRequested(
    VendorCommissionsLoadRequested event,
    Emitter<VendorCommissionsState> emit,
  ) async {
    emit(state.copyWith(status: VendorCommissionsStatus.loading, message: ''));
    await _load(emit);
  }

  Future<void> _onRefreshed(
    VendorCommissionsRefreshed event,
    Emitter<VendorCommissionsState> emit,
  ) async {
    emit(state.copyWith(status: VendorCommissionsStatus.loading, message: ''));
    await _load(emit);
  }

  Future<void> _onFilterChanged(
    VendorCommissionsFilterChanged event,
    Emitter<VendorCommissionsState> emit,
  ) async {
    emit(state.copyWith(status: VendorCommissionsStatus.loading, filter: event.status, message: ''));
    await _load(emit);
  }
}
