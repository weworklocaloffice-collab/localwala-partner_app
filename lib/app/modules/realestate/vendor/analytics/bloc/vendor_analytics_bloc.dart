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

part 'vendor_analytics_event.dart';
part 'vendor_analytics_state.dart';

/// Listing analytics (plan §11.3): views, enquiries, leads, visits,
/// conversion. Read-only tiles over the server snapshot — the server
/// owns the counters, the app never derives them.
class VendorAnalyticsBloc extends Bloc<VendorAnalyticsEvent, VendorAnalyticsState> {
  VendorAnalyticsBloc({RealEstateVendorRepository? repository})
      : _repository = repository ?? RealEstateVendorRepository(),
        super(const VendorAnalyticsState()) {
    on<VendorAnalyticsLoadRequested>(_onLoadRequested);
    on<VendorAnalyticsRefreshed>(_onRefreshed);
  }

  final RealEstateVendorRepository _repository;

  Future<void> _load(Emitter<VendorAnalyticsState> emit) async {
    try {
      final Map<String, dynamic> data = await _repository.analytics();
      emit(state.copyWith(status: VendorAnalyticsStatus.loaded, data: data));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: VendorAnalyticsStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: VendorAnalyticsStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onLoadRequested(
    VendorAnalyticsLoadRequested event,
    Emitter<VendorAnalyticsState> emit,
  ) async {
    emit(state.copyWith(status: VendorAnalyticsStatus.loading, message: ''));
    await _load(emit);
  }

  Future<void> _onRefreshed(
    VendorAnalyticsRefreshed event,
    Emitter<VendorAnalyticsState> emit,
  ) async {
    emit(state.copyWith(status: VendorAnalyticsStatus.loading, message: ''));
    await _load(emit);
  }
}
