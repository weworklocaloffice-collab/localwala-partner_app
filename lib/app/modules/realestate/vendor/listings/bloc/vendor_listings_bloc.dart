/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'vendor_listings_event.dart';
part 'vendor_listings_state.dart';

/// Tab ids. Each id doubles as the `status` list filter, except [listingsTabAll]
/// (unfiltered) and [listingsTabSoldRented] (SOLD + RENTED merged — the API
/// takes one status per request, and a rental vendor's closed deals are split
/// across both).
const String listingsTabAll = 'all';
const String listingsTabSoldRented = 'SOLD_RENTED';

/// The nine listing tabs in order (blueprint §39).
class ListingsTab {
  final String id;
  final String label;

  const ListingsTab({required this.id, required this.label});
}

const List<ListingsTab> listingsTabs = <ListingsTab>[
  ListingsTab(id: listingsTabAll, label: 'All'),
  ListingsTab(id: 'DRAFT', label: 'Draft'),
  ListingsTab(id: 'SUBMITTED', label: 'Submitted'),
  ListingsTab(id: 'IN_REVIEW', label: 'In review'),
  ListingsTab(id: 'CHANGES_REQUIRED', label: 'Changes needed'),
  ListingsTab(id: 'APPROVED', label: 'Approved'),
  ListingsTab(id: 'PUBLISHED', label: 'Published'),
  ListingsTab(id: listingsTabSoldRented, label: 'Sold / Rented'),
  ListingsTab(id: 'ARCHIVED', label: 'Archived'),
];

/// Statuses one tab fans out to. Null means unfiltered.
List<String>? listingsTabStatuses(String tabId) {
  if (tabId == listingsTabAll) return null;
  if (tabId == listingsTabSoldRented) return const <String>['SOLD', 'RENTED'];
  return <String>[tabId];
}

/// The vendor's listings, tabbed by lifecycle state with per-tab pages.
///
/// Each tab caches its loaded pages, so switching tabs never flashes a
/// spinner for data already held. A load that resolves after the user
/// switched away is dropped (stale guard on `activeTab`).
class VendorListingsBloc extends Bloc<VendorListingsEvent, VendorListingsState> {
  VendorListingsBloc({RealEstateVendorRepository? repository})
      : _repository = repository ?? RealEstateVendorRepository(),
        super(const VendorListingsState()) {
    on<VendorListingsTabSelected>(_onVendorListingsTabSelected);
    on<VendorListingsNextPage>(_onVendorListingsNextPage);
    on<VendorListingsRefreshed>(_onVendorListingsRefreshed);
  }

  static const int _limit = 20;

  final RealEstateVendorRepository _repository;

  Future<void> _onVendorListingsTabSelected(
    VendorListingsTabSelected event,
    Emitter<VendorListingsState> emit,
  ) async {
    if (event.tabId == state.activeTab && state.pages.containsKey(event.tabId)) return;
    emit(state.copyWith(
      activeTab: event.tabId,
      status: state.pages.containsKey(event.tabId) ? VendorListingsStatus.loaded : VendorListingsStatus.loading,
      message: '',
    ));
    if (!state.pages.containsKey(event.tabId)) {
      await _loadPage(emit, event.tabId, 1, append: false);
    }
  }

  Future<void> _onVendorListingsNextPage(
    VendorListingsNextPage event,
    Emitter<VendorListingsState> emit,
  ) async {
    if (!state.hasMore || state.loadingMore || state.status == VendorListingsStatus.loading) return;
    emit(state.copyWith(loadingMore: true));
    final int nextPage = (state.pages[state.activeTab]?.page ?? 1) + 1;
    await _loadPage(emit, state.activeTab, nextPage, append: true);
  }

  Future<void> _onVendorListingsRefreshed(
    VendorListingsRefreshed event,
    Emitter<VendorListingsState> emit,
  ) async {
    emit(state.copyWith(status: VendorListingsStatus.loading, message: ''));
    await _loadPage(emit, state.activeTab, 1, append: false);
  }

  Future<void> _loadPage(Emitter<VendorListingsState> emit, String tab, int page, {required bool append}) async {
    try {
      final RealEstatePage<RealEstatePropertyModel> fetched = await _fetchTab(tab, page);
      // The user may have switched tabs while this request was in flight —
      // a stale page must not overwrite the newly active tab.
      if (state.activeTab != tab) return;
      final List<RealEstatePropertyModel> previous =
          append ? (state.pages[tab]?.items ?? const <RealEstatePropertyModel>[]) : const <RealEstatePropertyModel>[];
      final Map<String, RealEstatePage<RealEstatePropertyModel>> pages =
          Map<String, RealEstatePage<RealEstatePropertyModel>>.from(state.pages);
      pages[tab] = RealEstatePage<RealEstatePropertyModel>(
        items: <RealEstatePropertyModel>[...previous, ...fetched.items],
        page: fetched.page,
        limit: fetched.limit,
        total: fetched.total,
      );
      emit(state.copyWith(
        pages: pages,
        status: VendorListingsStatus.loaded,
        loadingMore: false,
      ));
    } on RealEstateApiException catch (e) {
      if (state.activeTab != tab) return;
      emit(state.copyWith(status: VendorListingsStatus.failure, loadingMore: false, message: e.message));
    } catch (e) {
      if (state.activeTab != tab) return;
      emit(state.copyWith(status: VendorListingsStatus.failure, loadingMore: false, message: e.toString()));
    }
  }

  Future<RealEstatePage<RealEstatePropertyModel>> _fetchTab(String tab, int page) async {
    final List<String>? statuses = listingsTabStatuses(tab);
    if (statuses == null) {
      return _repository.properties(page: page, limit: _limit);
    }
    if (statuses.length == 1) {
      return _repository.properties(page: page, limit: _limit, status: statuses.first);
    }
    final List<RealEstatePage<RealEstatePropertyModel>> parts = await Future.wait(
      statuses.map((String s) => _repository.properties(page: page, limit: _limit, status: s)),
    );
    int total = 0;
    final List<RealEstatePropertyModel> items = <RealEstatePropertyModel>[];
    for (final RealEstatePage<RealEstatePropertyModel> part in parts) {
      total += part.total;
      items.addAll(part.items);
    }
    return RealEstatePage<RealEstatePropertyModel>(items: items, page: page, limit: _limit, total: total);
  }
}
