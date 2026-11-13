import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';

part 'stores_settings_event.dart';
part 'stores_settings_state.dart';

class StoresSettingsBloc extends Bloc<StoresSettingsEvent, StoresSettingsState> {
  StoresSettingsBloc({StoresPartnerRepository? repository})
      : _repository = repository ?? StoresPartnerRepository(),
        super(const StoresSettingsState()) {
    on<StoresSettingsLoadEvent>(_onLoad);
  }

  final StoresPartnerRepository _repository;

  Future<void> _onLoad(
    StoresSettingsLoadEvent event,
    Emitter<StoresSettingsState> emit,
  ) async {
    emit(state.copyWith(status: StoresSettingsStatus.loading, message: ''));
    try {
      final List<Map<String, dynamic>> outlets = await _repository.myOutlets();
      if (outlets.isEmpty) {
        emit(state.copyWith(status: StoresSettingsStatus.failure, message: 'No outlet'));
        return;
      }
      final String id = '${outlets.first['_id'] ?? outlets.first['id'] ?? ''}';
      if (id.isEmpty) {
        emit(state.copyWith(status: StoresSettingsStatus.failure, message: 'No outlet'));
        return;
      }
      final Map<String, dynamic> detail = await _repository.outletDetail(id);
      emit(state.copyWith(status: StoresSettingsStatus.loaded, outlet: detail));
    } on Object catch (e) {
      emit(state.copyWith(status: StoresSettingsStatus.failure, message: e.toString()));
    }
  }
}
