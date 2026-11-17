import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/lead_detail.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_lead_detail_event.dart';
part 'executive_lead_detail_state.dart';

class ExecutiveLeadDetailBloc extends Bloc<ExecutiveLeadDetailEvent, ExecutiveLeadDetailState> {
  ExecutiveLeadDetailBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveLeadDetailState()) {
    on<ExecutiveLeadDetailLoad>(_onLoad);
    on<ExecutiveLeadDetailRefreshed>(_onRefreshed);
  }

  final RealEstateExecutiveRepository _repository;

  Future<void> _onLoad(ExecutiveLeadDetailLoad event, Emitter<ExecutiveLeadDetailState> emit) async {
    emit(state.copyWith(status: ExecutiveLeadDetailStatus.loading, message: ''));
    await _fetch(event.leadId, emit);
  }

  Future<void> _onRefreshed(ExecutiveLeadDetailRefreshed event, Emitter<ExecutiveLeadDetailState> emit) async {
    emit(state.copyWith(status: ExecutiveLeadDetailStatus.loading, message: ''));
    await _fetch(event.leadId, emit);
  }

  Future<void> _fetch(String leadId, Emitter<ExecutiveLeadDetailState> emit) async {
    try {
      final detail = await _repository.lead(leadId);
      if (detail == null) {
        emit(state.copyWith(status: ExecutiveLeadDetailStatus.failure, message: 'Lead not found'));
        return;
      }
      emit(state.copyWith(status: ExecutiveLeadDetailStatus.loaded, detail: detail));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ExecutiveLeadDetailStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ExecutiveLeadDetailStatus.failure, message: e.toString()));
    }
  }
}
