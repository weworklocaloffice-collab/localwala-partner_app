import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_notifications_event.dart';
part 'executive_notifications_state.dart';

class ExecutiveNotificationsBloc extends Bloc<ExecutiveNotificationsEvent, ExecutiveNotificationsState> {
  ExecutiveNotificationsBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveNotificationsState()) {
    on<ExecutiveNotificationsLoad>(_onLoad);
    on<ExecutiveNotificationsRefreshed>(_onRefreshed);
  }

  final RealEstateExecutiveRepository _repository;

  Future<void> _onLoad(ExecutiveNotificationsLoad event, Emitter<ExecutiveNotificationsState> emit) async {
    emit(state.copyWith(status: ExecutiveNotificationsStatus.loading, message: ''));
    await _fetch(emit);
  }

  Future<void> _onRefreshed(ExecutiveNotificationsRefreshed event, Emitter<ExecutiveNotificationsState> emit) async {
    emit(state.copyWith(status: ExecutiveNotificationsStatus.loading, message: ''));
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<ExecutiveNotificationsState> emit) async {
    try {
      final items = await _repository.notifications(page: 1, limit: 50);
      emit(state.copyWith(status: ExecutiveNotificationsStatus.loaded, items: items));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ExecutiveNotificationsStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ExecutiveNotificationsStatus.failure, message: e.toString()));
    }
  }
}
