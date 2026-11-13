/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/visit.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'vendor_visits_event.dart';
part 'vendor_visits_state.dart';

/// The "all" tab id. Every other tab id doubles as its `status` filter —
/// visit states need no merging.
const String visitsTabAll = 'all';

/// The seven visit tabs: the model enum in schedule order.
class VisitsTab {
  final String id;
  final String label;

  const VisitsTab({required this.id, required this.label});
}

const List<VisitsTab> visitsTabs = <VisitsTab>[
  VisitsTab(id: visitsTabAll, label: 'All'),
  VisitsTab(id: 'ASSIGNED', label: 'Assigned'),
  VisitsTab(id: 'ACCEPTED', label: 'Accepted'),
  VisitsTab(id: 'CHECK_IN', label: 'Checked in'),
  VisitsTab(id: 'IN_PROGRESS', label: 'In progress'),
  VisitsTab(id: 'COMPLETED', label: 'Completed'),
  VisitsTab(id: 'CANCELLED', label: 'Cancelled'),
];

/// Status filter one tab queries. Null means unfiltered.
String? visitsTabStatus(String tabId) => tabId == visitsTabAll ? null : tabId;

/// The vendor's visit schedule, tabbed by state with per-tab pages.
///
/// Read-only by design: the vendor watches the schedule but cannot accept,
/// check in, complete or record interest — those are the executive's
/// geofenced actions (BR-08, BR-09). Same cached-pages pattern as the
/// listings and leads blocs.
class VendorVisitsBloc extends Bloc<VendorVisitsEvent, VendorVisitsState> {
  VendorVisitsBloc({RealEstateVendorRepository? repository})
      : _repository = repository ?? RealEstateVendorRepository(),
        super(const VendorVisitsState()) {
    on<VendorVisitsTabSelected>(_onVendorVisitsTabSelected);
    on<VendorVisitsNextPage>(_onVendorVisitsNextPage);
    on<VendorVisitsRefreshed>(_onVendorVisitsRefreshed);
  }

  static const int _limit = 20;

  final RealEstateVendorRepository _repository;

  Future<void> _onVendorVisitsTabSelected(
    VendorVisitsTabSelected event,
    Emitter<VendorVisitsState> emit,
  ) async {
    if (event.tabId == state.activeTab && state.pages.containsKey(event.tabId)) return;
    emit(state.copyWith(
      activeTab: event.tabId,
      status: state.pages.containsKey(event.tabId) ? VendorVisitsStatus.loaded : VendorVisitsStatus.loading,
      message: '',
    ));
    if (!state.pages.containsKey(event.tabId)) {
      await _loadPage(emit, event.tabId, 1, append: false);
    }
  }

  Future<void> _onVendorVisitsNextPage(
    VendorVisitsNextPage event,
    Emitter<VendorVisitsState> emit,
  ) async {
    if (!state.hasMore || state.loadingMore || state.status == VendorVisitsStatus.loading) return;
    emit(state.copyWith(loadingMore: true));
    final int nextPage = (state.pages[state.activeTab]?.page ?? 1) + 1;
    await _loadPage(emit, state.activeTab, nextPage, append: true);
  }

  Future<void> _onVendorVisitsRefreshed(
    VendorVisitsRefreshed event,
    Emitter<VendorVisitsState> emit,
  ) async {
    emit(state.copyWith(status: VendorVisitsStatus.loading, message: ''));
    await _loadPage(emit, state.activeTab, 1, append: false);
  }

  Future<void> _loadPage(Emitter<VendorVisitsState> emit, String tab, int page, {required bool append}) async {
    try {
      final RealEstatePage<RealEstateVisitModel> fetched = await _repository.visits(
        page: page,
        limit: _limit,
        status: visitsTabStatus(tab),
      );
      // The user may have switched tabs while this request was in flight —
      // a stale page must not overwrite the newly active tab.
      if (state.activeTab != tab) return;
      final List<RealEstateVisitModel> previous =
          append ? (state.pages[tab]?.items ?? const <RealEstateVisitModel>[]) : const <RealEstateVisitModel>[];
      final Map<String, RealEstatePage<RealEstateVisitModel>> pages =
          Map<String, RealEstatePage<RealEstateVisitModel>>.from(state.pages);
      pages[tab] = RealEstatePage<RealEstateVisitModel>(
        items: <RealEstateVisitModel>[...previous, ...fetched.items],
        page: fetched.page,
        limit: fetched.limit,
        total: fetched.total,
      );
      emit(state.copyWith(
        pages: pages,
        status: VendorVisitsStatus.loaded,
        loadingMore: false,
      ));
    } on RealEstateApiException catch (e) {
      if (state.activeTab != tab) return;
      emit(state.copyWith(status: VendorVisitsStatus.failure, loadingMore: false, message: e.message));
    } catch (e) {
      if (state.activeTab != tab) return;
      emit(state.copyWith(status: VendorVisitsStatus.failure, loadingMore: false, message: e.toString()));
    }
  }
}
