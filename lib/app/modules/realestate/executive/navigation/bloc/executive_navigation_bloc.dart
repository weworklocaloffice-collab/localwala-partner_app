import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_navigation_event.dart';
part 'executive_navigation_state.dart';

class ExecutiveNavigationBloc extends Bloc<ExecutiveNavigationEvent, ExecutiveNavigationState> {
  ExecutiveNavigationBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveNavigationState()) {
    on<ExecutiveNavigationLoad>(_onLoad);
    on<ExecutiveNavigationRefreshed>(_onRefreshed);
  }

  final RealEstateExecutiveRepository _repository;

  Future<void> _onLoad(ExecutiveNavigationLoad event, Emitter<ExecutiveNavigationState> emit) async {
    emit(state.copyWith(status: ExecutiveNavigationStatus.loading, message: ''));
    await _fetch(event.propertyId, emit);
  }

  Future<void> _onRefreshed(ExecutiveNavigationRefreshed event, Emitter<ExecutiveNavigationState> emit) async {
    emit(state.copyWith(status: ExecutiveNavigationStatus.loading, message: ''));
    await _fetch(event.propertyId, emit);
  }

  Future<void> _fetch(String propertyId, Emitter<ExecutiveNavigationState> emit) async {
    try {
      final property = await _repository.property(propertyId);
      if (property == null) {
        emit(state.copyWith(status: ExecutiveNavigationStatus.failure, message: 'Property not found'));
        return;
      }
      emit(state.copyWith(status: ExecutiveNavigationStatus.loaded, property: property));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ExecutiveNavigationStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ExecutiveNavigationStatus.failure, message: e.toString()));
    }
  }
}
