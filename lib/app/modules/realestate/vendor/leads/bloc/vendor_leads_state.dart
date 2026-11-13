/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_leads_bloc.dart';

enum VendorLeadsStatus { initial, loading, loaded, failure }

class VendorLeadsState {
  final String activeTab;
  final Map<String, RealEstatePage<RealEstateLeadModel>> pages;
  final VendorLeadsStatus status;
  final bool loadingMore;
  final String message;

  const VendorLeadsState({
    this.activeTab = leadsTabAll,
    this.pages = const <String, RealEstatePage<RealEstateLeadModel>>{},
    this.status = VendorLeadsStatus.initial,
    this.loadingMore = false,
    this.message = '',
  });

  List<RealEstateLeadModel> get items => pages[activeTab]?.items ?? const <RealEstateLeadModel>[];

  int get total => pages[activeTab]?.total ?? 0;

  bool get hasMore => items.length < total;

  VendorLeadsState copyWith({
    String? activeTab,
    Map<String, RealEstatePage<RealEstateLeadModel>>? pages,
    VendorLeadsStatus? status,
    bool? loadingMore,
    String? message,
  }) {
    return VendorLeadsState(
      activeTab: activeTab ?? this.activeTab,
      pages: pages ?? this.pages,
      status: status ?? this.status,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message ?? this.message,
    );
  }
}
