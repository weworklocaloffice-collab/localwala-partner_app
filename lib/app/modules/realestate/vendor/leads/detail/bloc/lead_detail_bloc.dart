/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/lead_detail.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'lead_detail_event.dart';
part 'lead_detail_state.dart';

/// One lead with its crossroads: customer, property, status, visits,
/// follow-ups, hold, sale and the latest loan status.
///
/// Read-only for the vendor — assignment, interest and completion belong
/// to the engine, the executive and the bank. No mutations, so no
/// transitioning state: load, refresh, render.
class LeadDetailBloc extends Bloc<LeadDetailEvent, LeadDetailState> {
  LeadDetailBloc({RealEstateVendorRepository? repository})
      : _repository = repository ?? RealEstateVendorRepository(),
        super(const LeadDetailState()) {
    on<LeadDetailLoadRequested>(_onLeadDetailLoadRequested);
    on<LeadDetailRefreshed>(_onLeadDetailRefreshed);
  }

  final RealEstateVendorRepository _repository;

  Future<void> _load(Emitter<LeadDetailState> emit, String leadId) async {
    try {
      final RealEstateLeadDetail? detail = await _repository.lead(leadId);
      if (detail == null) {
        emit(state.copyWith(status: LeadDetailStatus.failure, message: 'Lead not found'));
        return;
      }
      emit(state.copyWith(status: LeadDetailStatus.loaded, detail: () => detail));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: LeadDetailStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: LeadDetailStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onLeadDetailLoadRequested(
    LeadDetailLoadRequested event,
    Emitter<LeadDetailState> emit,
  ) async {
    emit(state.copyWith(status: LeadDetailStatus.loading, message: ''));
    await _load(emit, event.leadId);
  }

  Future<void> _onLeadDetailRefreshed(
    LeadDetailRefreshed event,
    Emitter<LeadDetailState> emit,
  ) async {
    final RealEstateLeadDetail? detail = state.detail;
    if (detail == null) return;
    emit(state.copyWith(status: LeadDetailStatus.loading, message: ''));
    await _load(emit, detail.lead.id);
  }
}
