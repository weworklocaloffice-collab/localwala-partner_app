import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';

part 'stores_returns_event.dart';
part 'stores_returns_state.dart';

class StoresReturnsBloc extends Bloc<StoresReturnsEvent, StoresReturnsState> {
  StoresReturnsBloc({StoresPartnerRepository? repository})
      : _repository = repository ?? StoresPartnerRepository(),
        super(const StoresReturnsState()) {
    on<StoresReturnsLoadEvent>(_onLoad);
  }

  final StoresPartnerRepository _repository;

  Future<void> _onLoad(
    StoresReturnsLoadEvent event,
    Emitter<StoresReturnsState> emit,
  ) async {
    emit(state.copyWith(status: StoresReturnsStatus.loading, message: ''));
    try {
      final Map<String, dynamic> body = await _repository.returns();
      final List<Map<String, dynamic>> rows = (body['items'] ?? body['returns'] ?? body['results'] ?? const <dynamic>[])
          .whereType<Map>()
          .map((Map<dynamic, dynamic> m) => Map<String, dynamic>.from(m))
          .toList();
      emit(state.copyWith(status: StoresReturnsStatus.loaded, rows: rows));
    } on Object catch (e) {
      emit(state.copyWith(status: StoresReturnsStatus.failure, message: e.toString()));
    }
  }
}
