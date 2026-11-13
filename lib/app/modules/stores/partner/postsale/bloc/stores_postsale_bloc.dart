import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';

part 'stores_postsale_event.dart';
part 'stores_postsale_state.dart';

class StoresPostSaleBloc extends Bloc<StoresPostSaleEvent, StoresPostSaleState> {
  StoresPostSaleBloc({StoresPartnerRepository? repository})
      : _repository = repository ?? StoresPartnerRepository(),
        super(const StoresPostSaleState()) {
    on<StoresPostSaleLoadEvent>(_onLoad);
  }

  final StoresPartnerRepository _repository;

  Future<void> _onLoad(
    StoresPostSaleLoadEvent event,
    Emitter<StoresPostSaleState> emit,
  ) async {
    emit(state.copyWith(status: StoresPostSaleStatus.loading, message: ''));
    try {
      final Map<String, dynamic> body = await _repository.returns();
      final List<Map<String, dynamic>> rows = (body['items'] ?? body['returns'] ?? body['results'] ?? const <dynamic>[])
          .whereType<Map>()
          .map((Map<dynamic, dynamic> m) => Map<String, dynamic>.from(m))
          .toList();
      emit(state.copyWith(status: StoresPostSaleStatus.loaded, rows: rows));
    } on Object catch (e) {
      emit(state.copyWith(status: StoresPostSaleStatus.failure, message: e.toString()));
    }
  }
}
