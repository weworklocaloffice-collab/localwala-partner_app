import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';

part 'stores_orders_event.dart';
part 'stores_orders_state.dart';

class StoresOrdersBloc extends Bloc<StoresOrdersEvent, StoresOrdersState> {
  StoresOrdersBloc({StoresPartnerRepository? repository})
      : _repository = repository ?? StoresPartnerRepository(),
        super(const StoresOrdersState()) {
    on<StoresOrdersLoadEvent>(_onLoad);
  }

  final StoresPartnerRepository _repository;

  Future<void> _onLoad(
    StoresOrdersLoadEvent event,
    Emitter<StoresOrdersState> emit,
  ) async {
    emit(state.copyWith(status: StoresOrdersStatus.loading, lifecycle: event.lifecycle, message: ''));
    try {
      final List<Map<String, dynamic>> orders = await _repository.orders(lifecycle: event.lifecycle);
      emit(state.copyWith(status: StoresOrdersStatus.loaded, orders: orders, lifecycle: event.lifecycle));
    } on Object catch (e) {
      emit(state.copyWith(status: StoresOrdersStatus.failure, message: e.toString()));
    }
  }
}
