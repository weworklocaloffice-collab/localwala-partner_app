/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/follow_up.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_followups_event.dart';
part 'executive_followups_state.dart';

/// Pending follow-ups for this executive, newest first.
///
/// Creation happens from a visit (`Schedule follow-up`); this tab lists
/// `GET /executive/followups` and completes them. No edit — a wrong
/// follow-up is completed and re-created.
class ExecutiveFollowUpsBloc extends Bloc<ExecutiveFollowUpsEvent, ExecutiveFollowUpsState> {
  ExecutiveFollowUpsBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveFollowUpsState()) {
    on<ExecutiveFollowUpsLoad>(_onLoad);
    on<ExecutiveFollowUpsNextPage>(_onNextPage);
    on<ExecutiveFollowUpsRefreshed>(_onRefreshed);
    on<ExecutiveFollowUpComplete>(_onComplete);
  }

  static const int _limit = 20;

  final RealEstateExecutiveRepository _repository;

  Future<void> _onLoad(ExecutiveFollowUpsLoad event, Emitter<ExecutiveFollowUpsState> emit) async {
    emit(state.copyWith(status: ExecutiveFollowUpsStatus.loading, message: ''));
    await _loadPage(emit, 1, append: false);
  }

  Future<void> _onNextPage(ExecutiveFollowUpsNextPage event, Emitter<ExecutiveFollowUpsState> emit) async {
    if (!state.hasMore || state.loadingMore || state.status == ExecutiveFollowUpsStatus.loading) return;
    emit(state.copyWith(loadingMore: true));
    await _loadPage(emit, state.page + 1, append: true);
  }

  Future<void> _onRefreshed(ExecutiveFollowUpsRefreshed event, Emitter<ExecutiveFollowUpsState> emit) async {
    emit(state.copyWith(status: ExecutiveFollowUpsStatus.loading, message: ''));
    await _loadPage(emit, 1, append: false);
  }

  Future<void> _onComplete(ExecutiveFollowUpComplete event, Emitter<ExecutiveFollowUpsState> emit) async {
    emit(state.copyWith(completingId: event.followUpId, actionError: ''));
    try {
      await _repository.completeFollowUp(event.followUpId);
      emit(state.copyWith(completingId: null));
      await _loadPage(emit, 1, append: false);
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(completingId: null, actionError: e.message));
    } catch (e) {
      emit(state.copyWith(completingId: null, actionError: e.toString()));
    }
  }

  Future<void> _loadPage(Emitter<ExecutiveFollowUpsState> emit, int page, {required bool append}) async {
    try {
      final RealEstatePage<RealEstateFollowUpModel> fetched = await _repository.followUps(page: page, limit: _limit);
      final List<RealEstateFollowUpModel> previous = append ? state.items : const <RealEstateFollowUpModel>[];
      emit(state.copyWith(
        items: <RealEstateFollowUpModel>[...previous, ...fetched.items],
        page: fetched.page,
        total: fetched.total,
        status: ExecutiveFollowUpsStatus.loaded,
        loadingMore: false,
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ExecutiveFollowUpsStatus.failure, loadingMore: false, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ExecutiveFollowUpsStatus.failure, loadingMore: false, message: e.toString()));
    }
  }
}
