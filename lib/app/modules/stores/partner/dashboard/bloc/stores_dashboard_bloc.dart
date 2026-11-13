import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';

part 'stores_dashboard_event.dart';
part 'stores_dashboard_state.dart';

class StoresDashboardBloc extends Bloc<StoresDashboardEvent, StoresDashboardState> {
  StoresDashboardBloc({StoresPartnerRepository? repository})
      : _repository = repository ?? StoresPartnerRepository(),
        super(const StoresDashboardState()) {
    on<StoresDashboardLoadEvent>(_onLoad);
  }

  final StoresPartnerRepository _repository;

  Future<void> _onLoad(
    StoresDashboardLoadEvent event,
    Emitter<StoresDashboardState> emit,
  ) async {
    emit(state.copyWith(status: StoresDashboardStatus.loading, message: ''));
    try {
      final Map<String, dynamic> data = await _repository.dashboard();
      emit(state.copyWith(status: StoresDashboardStatus.loaded, data: data));
    } on Object catch (e) {
      emit(state.copyWith(status: StoresDashboardStatus.failure, message: e.toString()));
    }
  }
}
