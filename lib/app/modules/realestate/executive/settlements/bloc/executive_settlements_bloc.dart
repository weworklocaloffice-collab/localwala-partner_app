import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/settlement.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_settlements_event.dart';
part 'executive_settlements_state.dart';

class ExecutiveSettlementsBloc extends Bloc<ExecutiveSettlementsEvent, ExecutiveSettlementsState> {
  ExecutiveSettlementsBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveSettlementsState()) {
    on<ExecutiveSettlementsLoad>(_onLoad);
    on<ExecutiveSettlementsNextPage>(_onNextPage);
    on<ExecutiveSettlementsRefreshed>(_onRefreshed);
  }

  static const int _limit = 20;

  final RealEstateExecutiveRepository _repository;

  Future<void> _onLoad(ExecutiveSettlementsLoad event, Emitter<ExecutiveSettlementsState> emit) async {
    emit(state.copyWith(status: ExecutiveSettlementsStatus.loading, message: ''));
    await _loadPage(emit, 1, append: false);
  }

  Future<void> _onNextPage(ExecutiveSettlementsNextPage event, Emitter<ExecutiveSettlementsState> emit) async {
    if (!state.hasMore || state.loadingMore || state.status == ExecutiveSettlementsStatus.loading) return;
    emit(state.copyWith(loadingMore: true));
    await _loadPage(emit, state.page + 1, append: true);
  }

  Future<void> _onRefreshed(ExecutiveSettlementsRefreshed event, Emitter<ExecutiveSettlementsState> emit) async {
    emit(state.copyWith(status: ExecutiveSettlementsStatus.loading, message: ''));
    await _loadPage(emit, 1, append: false);
  }

  Future<void> _loadPage(Emitter<ExecutiveSettlementsState> emit, int page, {required bool append}) async {
    try {
      final fetched = await _repository.settlements(page: page, limit: _limit);
      final List<RealEstateSettlementModel> previous = append ? state.items : const <RealEstateSettlementModel>[];
      emit(state.copyWith(
        items: <RealEstateSettlementModel>[...previous, ...fetched.items],
        page: fetched.page,
        total: fetched.total,
        status: ExecutiveSettlementsStatus.loaded,
        loadingMore: false,
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ExecutiveSettlementsStatus.failure, loadingMore: false, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ExecutiveSettlementsStatus.failure, loadingMore: false, message: e.toString()));
    }
  }
}
