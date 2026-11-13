/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_profile_event.dart';
part 'executive_profile_state.dart';

/// Executive identity: `GET /executive/me` plus a manual position
/// update. Location here is informational — check-in always measures
/// the coordinates sent with it, not this stored point.
class ExecutiveProfileBloc extends Bloc<ExecutiveProfileEvent, ExecutiveProfileState> {
  ExecutiveProfileBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveProfileState()) {
    on<ExecutiveProfileLoad>(_onLoad);
    on<ExecutiveProfileLocationUpdate>(_onLocationUpdate);
  }

  final RealEstateExecutiveRepository _repository;

  Future<void> _onLoad(ExecutiveProfileLoad event, Emitter<ExecutiveProfileState> emit) async {
    emit(state.copyWith(status: ExecutiveProfileStatus.loading, message: ''));
    try {
      final Map<String, dynamic> me = await _repository.me();
      emit(state.copyWith(status: ExecutiveProfileStatus.loaded, me: me));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ExecutiveProfileStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ExecutiveProfileStatus.failure, message: e.toString()));
    }
  }

  Future<void> _onLocationUpdate(ExecutiveProfileLocationUpdate event, Emitter<ExecutiveProfileState> emit) async {
    emit(state.copyWith(updatingLocation: true, locationSaved: false, locationMessage: ''));
    try {
      await _repository.updateLocation(lng: event.lng, lat: event.lat);
      final Map<String, dynamic> me = await _repository.me();
      emit(state.copyWith(
        updatingLocation: false,
        locationSaved: true,
        me: me,
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(updatingLocation: false, locationMessage: e.message));
    } catch (e) {
      emit(state.copyWith(updatingLocation: false, locationMessage: e.toString()));
    }
  }
}
