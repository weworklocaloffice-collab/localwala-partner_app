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

part 'vendor_dashboard_event.dart';
part 'vendor_dashboard_state.dart';

/// Loads the vendor dashboard: identity + publish eligibility plus the
/// analytics counters, in one parallel fetch.
///
/// Offline tolerant at the edges: a transport failure lands in `failure`
/// with the message, and the view offers a retry — never a crash, because
/// a vendor opens this screen first on every launch.
class VendorDashboardBloc extends Bloc<VendorDashboardEvent, VendorDashboardState> {
  VendorDashboardBloc({RealEstateVendorRepository? repository})
      : _repository = repository ?? RealEstateVendorRepository(),
        super(const VendorDashboardState()) {
    on<VendorDashboardLoadEvent>(_onVendorDashboardLoadEvent);
  }

  final RealEstateVendorRepository _repository;

  Future<void> _onVendorDashboardLoadEvent(
    VendorDashboardLoadEvent event,
    Emitter<VendorDashboardState> emit,
  ) async {
    emit(state.copyWith(status: VendorDashboardStatus.loading, message: ''));
    try {
      final List<Map<String, dynamic>> results = await Future.wait(
        <Future<Map<String, dynamic>>>[
          _repository.dashboard(),
          _repository.analytics(),
        ],
      );
      emit(
        state.copyWith(
          status: VendorDashboardStatus.loaded,
          summary: results[0],
          analytics: results[1],
        ),
      );
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: VendorDashboardStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: VendorDashboardStatus.failure, message: e.toString()));
    }
  }
}
