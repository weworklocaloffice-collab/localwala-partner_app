/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'vendor_customers_event.dart';
part 'vendor_customers_state.dart';

/// The vendor's customers: every customer behind a lead or a visit,
/// hydrated to contact rows by the backend.
///
/// A plain paged list — customers carry no lifecycle state, so there are
/// no tabs. Server order is most-recent first and pagination preserves
/// it; the list never re-sorts client-side.
class VendorCustomersBloc extends Bloc<VendorCustomersEvent, VendorCustomersState> {
  VendorCustomersBloc({RealEstateVendorRepository? repository})
      : _repository = repository ?? RealEstateVendorRepository(),
        super(const VendorCustomersState()) {
    on<VendorCustomersLoadRequested>(_onVendorCustomersLoadRequested);
    on<VendorCustomersNextPage>(_onVendorCustomersNextPage);
    on<VendorCustomersRefreshed>(_onVendorCustomersRefreshed);
  }

  static const int _limit = 20;

  final RealEstateVendorRepository _repository;

  Future<void> _load(Emitter<VendorCustomersState> emit, int page, {required bool append}) async {
    try {
      final RealEstatePage<RealEstateCustomerRef> fetched =
          await _repository.customers(page: page, limit: _limit);
      final List<RealEstateCustomerRef> items = append
          ? <RealEstateCustomerRef>[...state.items, ...fetched.items]
          : fetched.items;
      emit(state.copyWith(
        items: items,
        page: fetched.page,
        total: fetched.total,
        status: VendorCustomersStatus.loaded,
        loadingMore: false,
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: VendorCustomersStatus.failure, loadingMore: false, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: VendorCustomersStatus.failure, loadingMore: false, message: e.toString()));
    }
  }

  Future<void> _onVendorCustomersLoadRequested(
    VendorCustomersLoadRequested event,
    Emitter<VendorCustomersState> emit,
  ) async {
    emit(state.copyWith(status: VendorCustomersStatus.loading, message: ''));
    await _load(emit, 1, append: false);
  }

  Future<void> _onVendorCustomersNextPage(
    VendorCustomersNextPage event,
    Emitter<VendorCustomersState> emit,
  ) async {
    if (!state.hasMore || state.loadingMore || state.status == VendorCustomersStatus.loading) return;
    emit(state.copyWith(loadingMore: true));
    await _load(emit, state.page + 1, append: true);
  }

  Future<void> _onVendorCustomersRefreshed(
    VendorCustomersRefreshed event,
    Emitter<VendorCustomersState> emit,
  ) async {
    emit(state.copyWith(status: VendorCustomersStatus.loading, message: ''));
    await _load(emit, 1, append: false);
  }
}
