import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/visit.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_visit_detail_event.dart';
part 'executive_visit_detail_state.dart';

class ExecutiveVisitDetailBloc extends Bloc<ExecutiveVisitDetailEvent, ExecutiveVisitDetailState> {
  ExecutiveVisitDetailBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveVisitDetailState()) {
    on<ExecutiveVisitDetailLoad>(_onLoad);
    on<ExecutiveVisitDetailRefreshed>(_onRefreshed);
  }

  final RealEstateExecutiveRepository _repository;

  Future<void> _onLoad(ExecutiveVisitDetailLoad event, Emitter<ExecutiveVisitDetailState> emit) async {
    emit(state.copyWith(status: ExecutiveVisitDetailStatus.loading, message: ''));
    await _fetch(event.visitId, emit);
  }

  Future<void> _onRefreshed(ExecutiveVisitDetailRefreshed event, Emitter<ExecutiveVisitDetailState> emit) async {
    emit(state.copyWith(status: ExecutiveVisitDetailStatus.loading, message: ''));
    await _fetch(event.visitId, emit);
  }

  Future<void> _fetch(String visitId, Emitter<ExecutiveVisitDetailState> emit) async {
    try {
      final visit = await _repository.visit(visitId);
      if (visit == null) {
        emit(state.copyWith(status: ExecutiveVisitDetailStatus.failure, message: 'Visit not found'));
        return;
      }
      emit(state.copyWith(status: ExecutiveVisitDetailStatus.loaded, visit: visit));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ExecutiveVisitDetailStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ExecutiveVisitDetailStatus.failure, message: e.toString()));
    }
  }
}
