/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_visits_bloc.dart';

enum VendorVisitsStatus { initial, loading, loaded, failure }

class VendorVisitsState {
  final String activeTab;
  final Map<String, RealEstatePage<RealEstateVisitModel>> pages;
  final VendorVisitsStatus status;
  final bool loadingMore;
  final String message;

  const VendorVisitsState({
    this.activeTab = visitsTabAll,
    this.pages = const <String, RealEstatePage<RealEstateVisitModel>>{},
    this.status = VendorVisitsStatus.initial,
    this.loadingMore = false,
    this.message = '',
  });

  List<RealEstateVisitModel> get items => pages[activeTab]?.items ?? const <RealEstateVisitModel>[];

  int get total => pages[activeTab]?.total ?? 0;

  bool get hasMore => items.length < total;

  VendorVisitsState copyWith({
    String? activeTab,
    Map<String, RealEstatePage<RealEstateVisitModel>>? pages,
    VendorVisitsStatus? status,
    bool? loadingMore,
    String? message,
  }) {
    return VendorVisitsState(
      activeTab: activeTab ?? this.activeTab,
      pages: pages ?? this.pages,
      status: status ?? this.status,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message ?? this.message,
    );
  }
}
