/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/commission.dart';
import 'package:partner/app/modules/realestate/models/hold.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_today_event.dart';
part 'executive_today_state.dart';

/// Executive home counters: identity plus the dashboard aggregates.
///
/// One parallel fetch of `GET /executive/me` + `GET /executive/dashboard`
/// (totalVisits, visitsByStatus, activeLeads). Offline tolerant: a
/// transport failure lands in `failure` with a retry — never a crash,
/// because this is the first screen of every launch.
class ExecutiveTodayBloc extends Bloc<ExecutiveTodayEvent, ExecutiveTodayState> {
  ExecutiveTodayBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveTodayState()) {
    on<ExecutiveTodayLoad>(_onLoad);
  }

  final RealEstateExecutiveRepository _repository;

  Future<void> _onLoad(
    ExecutiveTodayLoad event,
    Emitter<ExecutiveTodayState> emit,
  ) async {
    emit(state.copyWith(status: ExecutiveTodayStatus.loading, message: ''));
    try {
      final List<dynamic> results = await Future.wait(
        <Future<dynamic>>[
          _repository.me(),
          _repository.dashboard(),
          _repository.holds(page: 1, limit: 5),
          _repository.commissions(page: 1, limit: 5),
          _repository.notifications(page: 1, limit: 20),
        ],
      );
      final List<Map<String, dynamic>> notifications =
          (results[4] as List<Map<String, dynamic>>);
      emit(
        state.copyWith(
          status: ExecutiveTodayStatus.loaded,
          me: results[0] as Map<String, dynamic>,
          dashboard: results[1] as Map<String, dynamic>,
          holds: results[2] as RealEstatePage<RealEstateHoldModel>,
          commissions: results[3] as RealEstatePage<RealEstateCommissionModel>,
          notifications: notifications,
          unreadCount: notifications.where((Map<String, dynamic> n) => n['readAt'] == null).length,
        ),
      );
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ExecutiveTodayStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ExecutiveTodayStatus.failure, message: e.toString()));
    }
  }
}
