/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'executive_followups_bloc.dart';

enum ExecutiveFollowUpsStatus { initial, loading, loaded, failure }

class ExecutiveFollowUpsState {
  final List<RealEstateFollowUpModel> items;
  final int page;
  final int total;
  final ExecutiveFollowUpsStatus status;
  final bool loadingMore;
  final String message;

  /// Follow-up currently being completed; its row shows a spinner.
  final String? completingId;

  final String actionError;

  const ExecutiveFollowUpsState({
    this.items = const <RealEstateFollowUpModel>[],
    this.page = 1,
    this.total = 0,
    this.status = ExecutiveFollowUpsStatus.initial,
    this.loadingMore = false,
    this.message = '',
    this.completingId,
    this.actionError = '',
  });

  bool get hasMore => items.length < total;

  ExecutiveFollowUpsState copyWith({
    List<RealEstateFollowUpModel>? items,
    int? page,
    int? total,
    ExecutiveFollowUpsStatus? status,
    bool? loadingMore,
    String? message,
    String? completingId,
    String? actionError,
  }) {
    return ExecutiveFollowUpsState(
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      status: status ?? this.status,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message ?? this.message,
      completingId: completingId,
      actionError: actionError ?? this.actionError,
    );
  }
}
