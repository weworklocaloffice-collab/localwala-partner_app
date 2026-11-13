import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';

part 'stores_delivery_event.dart';
part 'stores_delivery_state.dart';

class StoresDeliveryBloc extends Bloc<StoresDeliveryEvent, StoresDeliveryState> {
  StoresDeliveryBloc({StoresPartnerRepository? repository})
      : _repository = repository ?? StoresPartnerRepository(),
        super(const StoresDeliveryState()) {
    on<StoresDeliveryLoadEvent>(_onLoad);
  }

  final StoresPartnerRepository _repository;

  Future<void> _onLoad(
    StoresDeliveryLoadEvent event,
    Emitter<StoresDeliveryState> emit,
  ) async {
    emit(state.copyWith(status: StoresDeliveryStatus.loading, message: ''));
    try {
      final Map<String, dynamic> body = await _repository.deliveries();
      final List<Map<String, dynamic>> rows = (body['items'] ?? body['deliveries'] ?? body['results'] ?? const <dynamic>[])
          .whereType<Map>()
          .map((Map<dynamic, dynamic> m) => Map<String, dynamic>.from(m))
          .toList();
      emit(state.copyWith(status: StoresDeliveryStatus.loaded, rows: rows));
    } on Object catch (e) {
      emit(state.copyWith(status: StoresDeliveryStatus.failure, message: e.toString()));
    }
  }
}
