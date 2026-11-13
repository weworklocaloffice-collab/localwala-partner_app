/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'executive_leads_bloc.dart';

enum ExecutiveLeadsStatus { initial, loading, loaded, failure }

class ExecutiveLeadsState {
  final List<RealEstateLeadModel> items;
  final int page;
  final int total;
  final ExecutiveLeadsStatus status;
  final bool loadingMore;
  final String message;

  const ExecutiveLeadsState({
    this.items = const <RealEstateLeadModel>[],
    this.page = 1,
    this.total = 0,
    this.status = ExecutiveLeadsStatus.initial,
    this.loadingMore = false,
    this.message = '',
  });

  bool get hasMore => items.length < total;

  ExecutiveLeadsState copyWith({
    List<RealEstateLeadModel>? items,
    int? page,
    int? total,
    ExecutiveLeadsStatus? status,
    bool? loadingMore,
    String? message,
  }) {
    return ExecutiveLeadsState(
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      status: status ?? this.status,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message ?? this.message,
    );
  }
}
