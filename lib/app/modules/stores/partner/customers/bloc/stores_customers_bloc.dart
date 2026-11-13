import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';

part 'stores_customers_event.dart';
part 'stores_customers_state.dart';

class StoresCustomersBloc extends Bloc<StoresCustomersEvent, StoresCustomersState> {
  StoresCustomersBloc({StoresPartnerRepository? repository})
      : _repository = repository ?? StoresPartnerRepository(),
        super(const StoresCustomersState()) {
    on<StoresCustomersLoadEvent>(_onLoad);
  }

  final StoresPartnerRepository _repository;

  Future<void> _onLoad(
    StoresCustomersLoadEvent event,
    Emitter<StoresCustomersState> emit,
  ) async {
    emit(state.copyWith(status: StoresCustomersStatus.loading, message: ''));
    try {
      final Map<String, dynamic> body = await _repository.customers();
      final List<Map<String, dynamic>> rows = (body['items'] ?? body['customers'] ?? body['results'] ?? const <dynamic>[])
          .whereType<Map>()
          .map((Map<dynamic, dynamic> m) => Map<String, dynamic>.from(m))
          .toList();
      emit(state.copyWith(status: StoresCustomersStatus.loaded, rows: rows));
    } on Object catch (e) {
      emit(state.copyWith(status: StoresCustomersStatus.failure, message: e.toString()));
    }
  }
}
