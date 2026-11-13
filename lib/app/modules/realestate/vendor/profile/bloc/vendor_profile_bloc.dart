/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'vendor_profile_event.dart';
part 'vendor_profile_state.dart';

/// Vendor profile (plan §11.3): own record, verification status,
/// submit-for-review. KYC edits live in registration — this screen
/// never writes business fields, only the review transition.
class VendorProfileBloc extends Bloc<VendorProfileEvent, VendorProfileState> {
  VendorProfileBloc({RealEstateVendorRepository? repository})
      : _repository = repository ?? RealEstateVendorRepository(),
        super(const VendorProfileState()) {
    on<VendorProfileLoadRequested>(_onLoadRequested);
    on<VendorProfileRefreshed>(_onRefreshed);
    on<VendorProfileSubmitRequested>(_onSubmitRequested);
  }

  final RealEstateVendorRepository _repository;

  Future<void> _load(Emitter<VendorProfileState> emit) async {
    try {
      final Map<String, dynamic> vendor = await _repository.me();
      emit(state.copyWith(status: VendorProfileStatus.loaded, vendor: vendor));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: VendorProfileStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: VendorProfileStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onLoadRequested(
    VendorProfileLoadRequested event,
    Emitter<VendorProfileState> emit,
  ) async {
    emit(state.copyWith(status: VendorProfileStatus.loading, message: ''));
    await _load(emit);
  }

  Future<void> _onRefreshed(
    VendorProfileRefreshed event,
    Emitter<VendorProfileState> emit,
  ) async {
    emit(state.copyWith(status: VendorProfileStatus.loading, message: ''));
    await _load(emit);
  }

  Future<void> _onSubmitRequested(
    VendorProfileSubmitRequested event,
    Emitter<VendorProfileState> emit,
  ) async {
    try {
      await _repository.submitForReview();
      await _load(emit);
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: VendorProfileStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: VendorProfileStatus.failure, message: e.toString()));
    }
  }
}
