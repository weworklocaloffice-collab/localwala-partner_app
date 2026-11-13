import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';

part 'stores_inventory_event.dart';
part 'stores_inventory_state.dart';

class StoresInventoryBloc extends Bloc<StoresInventoryEvent, StoresInventoryState> {
  StoresInventoryBloc({StoresPartnerRepository? repository})
      : _repository = repository ?? StoresPartnerRepository(),
        super(const StoresInventoryState()) {
    on<StoresInventoryLoadEvent>(_onLoad);
  }

  final StoresPartnerRepository _repository;

  Future<void> _onLoad(
    StoresInventoryLoadEvent event,
    Emitter<StoresInventoryState> emit,
  ) async {
    emit(state.copyWith(status: StoresInventoryStatus.loading, lowOnly: event.lowOnly, message: ''));
    try {
      final Map<String, dynamic> body = event.lowOnly ? await _repository.lowStock() : await _repository.stock();
      final dynamic raw = body['items'] ?? body['stock'] ?? body['results'] ?? body;
      final List<Map<String, dynamic>> rows = raw is List
          ? raw.whereType<Map<String, dynamic>>().toList()
          : <Map<String, dynamic>>[];
      emit(state.copyWith(status: StoresInventoryStatus.loaded, rows: rows, lowOnly: event.lowOnly));
    } on Object catch (e) {
      emit(state.copyWith(status: StoresInventoryStatus.failure, message: e.toString()));
    }
  }
}
