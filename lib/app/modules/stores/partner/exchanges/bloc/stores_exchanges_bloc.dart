import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';

part 'stores_exchanges_event.dart';
part 'stores_exchanges_state.dart';

class StoresExchangesBloc extends Bloc<StoresExchangesEvent, StoresExchangesState> {
  StoresExchangesBloc({StoresPartnerRepository? repository})
      : _repository = repository ?? StoresPartnerRepository(),
        super(const StoresExchangesState()) {
    on<StoresExchangesLoadEvent>(_onLoad);
  }

  final StoresPartnerRepository _repository;

  Future<void> _onLoad(
    StoresExchangesLoadEvent event,
    Emitter<StoresExchangesState> emit,
  ) async {
    emit(state.copyWith(status: StoresExchangesStatus.loading, message: ''));
    try {
      final Map<String, dynamic> body = await _repository.exchanges();
      final List<Map<String, dynamic>> rows = (body['items'] ?? body['exchanges'] ?? body['results'] ?? const <dynamic>[])
          .whereType<Map>()
          .map((Map<dynamic, dynamic> m) => Map<String, dynamic>.from(m))
          .toList();
      emit(state.copyWith(status: StoresExchangesStatus.loaded, rows: rows));
    } on Object catch (e) {
      emit(state.copyWith(status: StoresExchangesStatus.failure, message: e.toString()));
    }
  }
}
