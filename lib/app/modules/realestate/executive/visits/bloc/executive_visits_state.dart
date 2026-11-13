/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'executive_visits_bloc.dart';

enum ExecutiveVisitsStatus { initial, loading, loaded, failure }

class ExecutiveVisitsState {
  final String activeTab;
  final Map<String, RealEstatePage<RealEstateVisitModel>> pages;
  final ExecutiveVisitsStatus status;
  final bool loadingMore;
  final String message;

  /// Visit currently under a transition; its row shows a spinner.
  final String? actingId;

  /// Last transition failure (e.g. geofence 403 with distance).
  final String actionError;

  const ExecutiveVisitsState({
    this.activeTab = executiveVisitsTabAll,
    this.pages = const <String, RealEstatePage<RealEstateVisitModel>>{},
    this.status = ExecutiveVisitsStatus.initial,
    this.loadingMore = false,
    this.message = '',
    this.actingId,
    this.actionError = '',
  });

  List<RealEstateVisitModel> get items => pages[activeTab]?.items ?? const <RealEstateVisitModel>[];

  int get total => pages[activeTab]?.total ?? 0;

  bool get hasMore => items.length < total;

  ExecutiveVisitsState copyWith({
    String? activeTab,
    Map<String, RealEstatePage<RealEstateVisitModel>>? pages,
    ExecutiveVisitsStatus? status,
    bool? loadingMore,
    String? message,
    String? actingId,
    String? actionError,
  }) {
    return ExecutiveVisitsState(
      activeTab: activeTab ?? this.activeTab,
      pages: pages ?? this.pages,
      status: status ?? this.status,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message ?? this.message,
      actingId: actingId,
      actionError: actionError ?? this.actionError,
    );
  }
}
