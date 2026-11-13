/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/visit.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_visits_event.dart';
part 'executive_visits_state.dart';

/// The "all" tab id. Every other tab id doubles as its `status` filter.
const String executiveVisitsTabAll = 'all';

/// Visit tabs in schedule order. Backend statuses are the tab ids.
class ExecutiveVisitsTab {
  final String id;
  final String label;

  const ExecutiveVisitsTab({required this.id, required this.label});
}

const List<ExecutiveVisitsTab> executiveVisitsTabs = <ExecutiveVisitsTab>[
  ExecutiveVisitsTab(id: executiveVisitsTabAll, label: 'All'),
  ExecutiveVisitsTab(id: 'ASSIGNED', label: 'Assigned'),
  ExecutiveVisitsTab(id: 'ACCEPTED', label: 'Accepted'),
  ExecutiveVisitsTab(id: 'CHECK_IN', label: 'Checked in'),
  ExecutiveVisitsTab(id: 'IN_PROGRESS', label: 'In progress'),
  ExecutiveVisitsTab(id: 'COMPLETED', label: 'Completed'),
  ExecutiveVisitsTab(id: 'CANCELLED', label: 'Cancelled'),
];

/// Status filter one tab queries. Null means unfiltered.
String? executiveVisitsTabStatus(String tabId) => tabId == executiveVisitsTabAll ? null : tabId;

/// The executive's work queue: accept → check-in (geofenced, BR-08) →
/// complete/cancel, plus notes and follow-up scheduling.
///
/// Named transitions only — never a generic status setter. A check-in
/// outside the visit radius fails with the distance message, not a
/// generic error.
class ExecutiveVisitsBloc extends Bloc<ExecutiveVisitsEvent, ExecutiveVisitsState> {
  ExecutiveVisitsBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveVisitsState()) {
    on<ExecutiveVisitsTabSelected>(_onTabSelected);
    on<ExecutiveVisitsNextPage>(_onNextPage);
    on<ExecutiveVisitsRefreshed>(_onRefreshed);
    on<ExecutiveVisitAccept>(_onAccept);
    on<ExecutiveVisitCheckIn>(_onCheckIn);
    on<ExecutiveVisitComplete>(_onComplete);
    on<ExecutiveVisitCancel>(_onCancel);
    on<ExecutiveVisitAddNotes>(_onAddNotes);
    on<ExecutiveVisitRecordInterest>(_onRecordInterest);
    on<ExecutiveVisitScheduleFollowUp>(_onScheduleFollowUp);
  }

  static const int _limit = 20;

  final RealEstateExecutiveRepository _repository;

  Future<void> _onTabSelected(
    ExecutiveVisitsTabSelected event,
    Emitter<ExecutiveVisitsState> emit,
  ) async {
    if (event.tabId == state.activeTab && state.pages.containsKey(event.tabId)) return;
    emit(state.copyWith(
      activeTab: event.tabId,
      status: state.pages.containsKey(event.tabId) ? ExecutiveVisitsStatus.loaded : ExecutiveVisitsStatus.loading,
      message: '',
      actionError: '',
    ));
    if (!state.pages.containsKey(event.tabId)) {
      await _loadPage(emit, event.tabId, 1, append: false);
    }
  }

  Future<void> _onNextPage(
    ExecutiveVisitsNextPage event,
    Emitter<ExecutiveVisitsState> emit,
  ) async {
    if (!state.hasMore || state.loadingMore || state.status == ExecutiveVisitsStatus.loading) return;
    emit(state.copyWith(loadingMore: true));
    final int nextPage = (state.pages[state.activeTab]?.page ?? 1) + 1;
    await _loadPage(emit, state.activeTab, nextPage, append: true);
  }

  Future<void> _onRefreshed(
    ExecutiveVisitsRefreshed event,
    Emitter<ExecutiveVisitsState> emit,
  ) async {
    emit(state.copyWith(status: ExecutiveVisitsStatus.loading, message: '', actionError: ''));
    await _loadPage(emit, state.activeTab, 1, append: false);
  }

  Future<void> _loadPage(Emitter<ExecutiveVisitsState> emit, String tab, int page, {required bool append}) async {
    try {
      final RealEstatePage<RealEstateVisitModel> fetched = await _repository.visits(
        page: page,
        limit: _limit,
        status: executiveVisitsTabStatus(tab),
      );
      if (state.activeTab != tab) return;
      final List<RealEstateVisitModel> previous =
          append ? (state.pages[tab]?.items ?? const <RealEstateVisitModel>[]) : const <RealEstateVisitModel>[];
      final Map<String, RealEstatePage<RealEstateVisitModel>> pages =
          Map<String, RealEstatePage<RealEstateVisitModel>>.from(state.pages);
      pages[tab] = RealEstatePage<RealEstateVisitModel>(
        items: <RealEstateVisitModel>[...previous, ...fetched.items],
        page: fetched.page,
        limit: fetched.limit,
        total: fetched.total,
      );
      emit(state.copyWith(pages: pages, status: ExecutiveVisitsStatus.loaded, loadingMore: false));
    } on RealEstateApiException catch (e) {
      if (state.activeTab != tab) return;
      emit(state.copyWith(status: ExecutiveVisitsStatus.failure, loadingMore: false, message: e.message));
    } catch (e) {
      if (state.activeTab != tab) return;
      emit(state.copyWith(status: ExecutiveVisitsStatus.failure, loadingMore: false, message: e.toString()));
    }
  }

  Future<void> _mutate(
    Emitter<ExecutiveVisitsState> emit,
    String visitId,
    Future<dynamic> Function() call,
  ) async {
    emit(state.copyWith(actingId: visitId, actionError: ''));
    try {
      await call();
      emit(state.copyWith(actingId: null));
      await _loadPage(emit, state.activeTab, 1, append: false);
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(actingId: null, actionError: e.message));
    } catch (e) {
      emit(state.copyWith(actingId: null, actionError: e.toString()));
    }
  }

  Future<void> _onAccept(ExecutiveVisitAccept event, Emitter<ExecutiveVisitsState> emit) =>
      _mutate(emit, event.visitId, () => _repository.acceptVisit(event.visitId));

  Future<void> _onCheckIn(ExecutiveVisitCheckIn event, Emitter<ExecutiveVisitsState> emit) =>
      _mutate(emit, event.visitId, () => _repository.checkIn(event.visitId, lng: event.lng, lat: event.lat));

  Future<void> _onComplete(ExecutiveVisitComplete event, Emitter<ExecutiveVisitsState> emit) =>
      _mutate(emit, event.visitId, () => _repository.completeVisit(event.visitId, notes: event.notes));

  Future<void> _onCancel(ExecutiveVisitCancel event, Emitter<ExecutiveVisitsState> emit) =>
      _mutate(emit, event.visitId, () => _repository.cancelVisit(event.visitId, reason: event.reason));

  Future<void> _onAddNotes(ExecutiveVisitAddNotes event, Emitter<ExecutiveVisitsState> emit) =>
      _mutate(emit, event.visitId, () => _repository.addVisitNotes(event.visitId, event.notes));

  Future<void> _onRecordInterest(ExecutiveVisitRecordInterest event, Emitter<ExecutiveVisitsState> emit) =>
      _mutate(
        emit,
        event.visitId,
        () => _repository.recordInterest(
          event.visitId,
          level: event.level,
          reason: event.reason,
          reasonText: event.reasonText,
        ),
      );

  Future<void> _onScheduleFollowUp(ExecutiveVisitScheduleFollowUp event, Emitter<ExecutiveVisitsState> emit) async {
    emit(state.copyWith(actingId: event.visitId, actionError: ''));
    try {
      await _repository.createFollowUp(
        event.leadId,
        nextFollowUpAt: event.nextFollowUpAt,
        mode: event.mode,
        notes: event.notes,
      );
      emit(state.copyWith(actingId: null));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(actingId: null, actionError: e.message));
    } catch (e) {
      emit(state.copyWith(actingId: null, actionError: e.toString()));
    }
  }
}
