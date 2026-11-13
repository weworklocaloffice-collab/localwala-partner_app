/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_customers_bloc.dart';

enum VendorCustomersStatus { initial, loading, loaded, failure }

class VendorCustomersState {
  final List<RealEstateCustomerRef> items;
  final int page;
  final int total;
  final VendorCustomersStatus status;
  final bool loadingMore;
  final String message;

  const VendorCustomersState({
    this.items = const <RealEstateCustomerRef>[],
    this.page = 1,
    this.total = 0,
    this.status = VendorCustomersStatus.initial,
    this.loadingMore = false,
    this.message = '',
  });

  bool get hasMore => items.length < total;

  VendorCustomersState copyWith({
    List<RealEstateCustomerRef>? items,
    int? page,
    int? total,
    VendorCustomersStatus? status,
    bool? loadingMore,
    String? message,
  }) {
    return VendorCustomersState(
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      status: status ?? this.status,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message ?? this.message,
    );
  }
}
