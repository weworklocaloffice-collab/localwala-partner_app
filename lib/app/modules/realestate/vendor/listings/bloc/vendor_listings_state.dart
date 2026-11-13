/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_listings_bloc.dart';

enum VendorListingsStatus { initial, loading, loaded, failure }

class VendorListingsState {
  final String activeTab;
  final Map<String, RealEstatePage<RealEstatePropertyModel>> pages;
  final VendorListingsStatus status;
  final bool loadingMore;
  final String message;

  const VendorListingsState({
    this.activeTab = listingsTabAll,
    this.pages = const <String, RealEstatePage<RealEstatePropertyModel>>{},
    this.status = VendorListingsStatus.initial,
    this.loadingMore = false,
    this.message = '',
  });

  List<RealEstatePropertyModel> get items => pages[activeTab]?.items ?? const <RealEstatePropertyModel>[];

  int get total => pages[activeTab]?.total ?? 0;

  bool get hasMore => items.length < total;

  VendorListingsState copyWith({
    String? activeTab,
    Map<String, RealEstatePage<RealEstatePropertyModel>>? pages,
    VendorListingsStatus? status,
    bool? loadingMore,
    String? message,
  }) {
    return VendorListingsState(
      activeTab: activeTab ?? this.activeTab,
      pages: pages ?? this.pages,
      status: status ?? this.status,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message ?? this.message,
    );
  }
}
