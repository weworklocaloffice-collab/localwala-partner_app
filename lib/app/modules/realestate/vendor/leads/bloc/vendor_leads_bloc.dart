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

part 'vendor_leads_event.dart';
part 'vendor_leads_state.dart';

/// The "all" tab id. Every other tab id doubles as its `status` filter —
/// lead states need no merging, unlike sold/rented listings.
const String leadsTabAll = 'all';

/// The ten lead tabs in lifecycle order.
class LeadsTab {
  final String id;
  final String label;

  const LeadsTab({required this.id, required this.label});
}

const List<LeadsTab> leadsTabs = <LeadsTab>[
  LeadsTab(id: leadsTabAll, label: 'All'),
  LeadsTab(id: 'NEW', label: 'New'),
  LeadsTab(id: 'CONTACTED', label: 'Contacted'),
  LeadsTab(id: 'VISIT_REQUESTED', label: 'Visit requested'),
  LeadsTab(id: 'VISIT_SCHEDULED', label: 'Visit scheduled'),
  LeadsTab(id: 'VISIT_COMPLETED', label: 'Visit completed'),
  LeadsTab(id: 'FOLLOW_UP', label: 'Follow-up'),
  LeadsTab(id: 'HOLD', label: 'Hold'),
  LeadsTab(id: 'SALE', label: 'Sale'),
  LeadsTab(id: 'LOST', label: 'Lost'),
];

/// Status filter one tab queries. Null means unfiltered.
String? leadsTabStatus(String tabId) => tabId == leadsTabAll ? null : tabId;

/// The vendor's leads, tabbed by lifecycle state with per-tab pages.
///
/// Same cached-pages pattern as the listings bloc: switching tabs never
/// re-spinners cached data, and a load that resolves after a switch is
/// dropped. Lead rows arrive with customer and property populated.
class VendorLeadsBloc extends Bloc<VendorLeadsEvent, VendorLeadsState> {
  VendorLeadsBloc({RealEstateVendorRepository? repository})
      : _repository = repository ?? RealEstateVendorRepository(),
        super(const VendorLeadsState()) {
    on<VendorLeadsTabSelected>(_onVendorLeadsTabSelected);
    on<VendorLeadsNextPage>(_onVendorLeadsNextPage);
    on<VendorLeadsRefreshed>(_onVendorLeadsRefreshed);
  }

  static const int _limit = 20;

  final RealEstateVendorRepository _repository;

  Future<void> _onVendorLeadsTabSelected(
    VendorLeadsTabSelected event,
    Emitter<VendorLeadsState> emit,
  ) async {
    if (event.tabId == state.activeTab && state.pages.containsKey(event.tabId)) return;
    emit(state.copyWith(
      activeTab: event.tabId,
      status: state.pages.containsKey(event.tabId) ? VendorLeadsStatus.loaded : VendorLeadsStatus.loading,
      message: '',
    ));
    if (!state.pages.containsKey(event.tabId)) {
      await _loadPage(emit, event.tabId, 1, append: false);
    }
  }

  Future<void> _onVendorLeadsNextPage(
    VendorLeadsNextPage event,
    Emitter<VendorLeadsState> emit,
  ) async {
    if (!state.hasMore || state.loadingMore || state.status == VendorLeadsStatus.loading) return;
    emit(state.copyWith(loadingMore: true));
    final int nextPage = (state.pages[state.activeTab]?.page ?? 1) + 1;
    await _loadPage(emit, state.activeTab, nextPage, append: true);
  }

  Future<void> _onVendorLeadsRefreshed(
    VendorLeadsRefreshed event,
    Emitter<VendorLeadsState> emit,
  ) async {
    emit(state.copyWith(status: VendorLeadsStatus.loading, message: ''));
    await _loadPage(emit, state.activeTab, 1, append: false);
  }

  Future<void> _loadPage(Emitter<VendorLeadsState> emit, String tab, int page, {required bool append}) async {
    try {
      final RealEstatePage<RealEstateLeadModel> fetched = await _repository.leads(
        page: page,
        limit: _limit,
        status: leadsTabStatus(tab),
      );
      // The user may have switched tabs while this request was in flight —
      // a stale page must not overwrite the newly active tab.
      if (state.activeTab != tab) return;
      final List<RealEstateLeadModel> previous =
          append ? (state.pages[tab]?.items ?? const <RealEstateLeadModel>[]) : const <RealEstateLeadModel>[];
      final Map<String, RealEstatePage<RealEstateLeadModel>> pages =
          Map<String, RealEstatePage<RealEstateLeadModel>>.from(state.pages);
      pages[tab] = RealEstatePage<RealEstateLeadModel>(
        items: <RealEstateLeadModel>[...previous, ...fetched.items],
        page: fetched.page,
        limit: fetched.limit,
        total: fetched.total,
      );
      emit(state.copyWith(
        pages: pages,
        status: VendorLeadsStatus.loaded,
        loadingMore: false,
      ));
    } on RealEstateApiException catch (e) {
      if (state.activeTab != tab) return;
      emit(state.copyWith(status: VendorLeadsStatus.failure, loadingMore: false, message: e.message));
    } catch (e) {
      if (state.activeTab != tab) return;
      emit(state.copyWith(status: VendorLeadsStatus.failure, loadingMore: false, message: e.toString()));
    }
  }
}
