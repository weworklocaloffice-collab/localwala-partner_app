/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'executive_today_bloc.dart';

enum ExecutiveTodayStatus { initial, loading, loaded, failure }

class ExecutiveTodayState {
  final ExecutiveTodayStatus status;

  /// `GET /executive/me`: identity, availability, assignment scope.
  final Map<String, dynamic> me;

  /// `GET /executive/dashboard`: totalVisits, visitsByStatus, activeLeads.
  final Map<String, dynamic> dashboard;

  /// Latest holds on my leads (read-only, plan §11.4).
  final RealEstatePage<RealEstateHoldModel>? holds;

  /// Latest commission rows for me (BR-15 snapshots, never restated).
  final RealEstatePage<RealEstateCommissionModel>? commissions;

  /// Latest notifications; `readAt == null` means unread.
  final List<Map<String, dynamic>> notifications;

  final int unreadCount;

  final String message;

  const ExecutiveTodayState({
    this.status = ExecutiveTodayStatus.initial,
    this.me = const <String, dynamic>{},
    this.dashboard = const <String, dynamic>{},
    this.holds,
    this.commissions,
    this.notifications = const <Map<String, dynamic>>[],
    this.unreadCount = 0,
    this.message = '',
  });

  ExecutiveTodayState copyWith({
    ExecutiveTodayStatus? status,
    Map<String, dynamic>? me,
    Map<String, dynamic>? dashboard,
    RealEstatePage<RealEstateHoldModel>? holds,
    RealEstatePage<RealEstateCommissionModel>? commissions,
    List<Map<String, dynamic>>? notifications,
    int? unreadCount,
    String? message,
  }) {
    return ExecutiveTodayState(
      status: status ?? this.status,
      me: me ?? this.me,
      dashboard: dashboard ?? this.dashboard,
      holds: holds ?? this.holds,
      commissions: commissions ?? this.commissions,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      message: message ?? this.message,
    );
  }
}
