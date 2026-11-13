/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_leads_event.dart';
part 'executive_leads_state.dart';

/// This executive's assigned leads, newest first, paginated.
///
/// Read-only list — assignment is server side (BR-07). Tapping a row
/// loads `GET /executive/leads/:leadId` for the detail sheet.
class ExecutiveLeadsBloc extends Bloc<ExecutiveLeadsEvent, ExecutiveLeadsState> {
  ExecutiveLeadsBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveLeadsState()) {
    on<ExecutiveLeadsLoad>(_onLoad);
    on<ExecutiveLeadsNextPage>(_onNextPage);
    on<ExecutiveLeadsRefreshed>(_onRefreshed);
  }

  static const int _limit = 20;

  final RealEstateExecutiveRepository _repository;

  Future<void> _onLoad(
    ExecutiveLeadsLoad event,
    Emitter<ExecutiveLeadsState> emit,
  ) async {
    emit(state.copyWith(status: ExecutiveLeadsStatus.loading, message: ''));
    await _loadPage(emit, 1, append: false);
  }

  Future<void> _onNextPage(
    ExecutiveLeadsNextPage event,
    Emitter<ExecutiveLeadsState> emit,
  ) async {
    if (!state.hasMore || state.loadingMore || state.status == ExecutiveLeadsStatus.loading) return;
    emit(state.copyWith(loadingMore: true));
    await _loadPage(emit, state.page + 1, append: true);
  }

  Future<void> _onRefreshed(
    ExecutiveLeadsRefreshed event,
    Emitter<ExecutiveLeadsState> emit,
  ) async {
    emit(state.copyWith(status: ExecutiveLeadsStatus.loading, message: ''));
    await _loadPage(emit, 1, append: false);
  }

  Future<void> _loadPage(Emitter<ExecutiveLeadsState> emit, int page, {required bool append}) async {
    try {
      final RealEstatePage<RealEstateLeadModel> fetched = await _repository.leads(page: page, limit: _limit);
      final List<RealEstateLeadModel> previous = append ? state.items : const <RealEstateLeadModel>[];
      emit(state.copyWith(
        items: <RealEstateLeadModel>[...previous, ...fetched.items],
        page: fetched.page,
        total: fetched.total,
        status: ExecutiveLeadsStatus.loaded,
        loadingMore: false,
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ExecutiveLeadsStatus.failure, loadingMore: false, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ExecutiveLeadsStatus.failure, loadingMore: false, message: e.toString()));
    }
  }
}
