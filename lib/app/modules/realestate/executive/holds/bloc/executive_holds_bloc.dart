import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/hold.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_holds_event.dart';
part 'executive_holds_state.dart';

class ExecutiveHoldsBloc extends Bloc<ExecutiveHoldsEvent, ExecutiveHoldsState> {
  ExecutiveHoldsBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveHoldsState()) {
    on<ExecutiveHoldsLoad>(_onLoad);
    on<ExecutiveHoldsNextPage>(_onNextPage);
    on<ExecutiveHoldsRefreshed>(_onRefreshed);
  }

  static const int _limit = 20;

  final RealEstateExecutiveRepository _repository;

  Future<void> _onLoad(ExecutiveHoldsLoad event, Emitter<ExecutiveHoldsState> emit) async {
    emit(state.copyWith(status: ExecutiveHoldsStatus.loading, message: ''));
    await _loadPage(emit, 1, append: false);
  }

  Future<void> _onNextPage(ExecutiveHoldsNextPage event, Emitter<ExecutiveHoldsState> emit) async {
    if (!state.hasMore || state.loadingMore || state.status == ExecutiveHoldsStatus.loading) return;
    emit(state.copyWith(loadingMore: true));
    await _loadPage(emit, state.page + 1, append: true);
  }

  Future<void> _onRefreshed(ExecutiveHoldsRefreshed event, Emitter<ExecutiveHoldsState> emit) async {
    emit(state.copyWith(status: ExecutiveHoldsStatus.loading, message: ''));
    await _loadPage(emit, 1, append: false);
  }

  Future<void> _loadPage(Emitter<ExecutiveHoldsState> emit, int page, {required bool append}) async {
    try {
      final fetched = await _repository.holds(page: page, limit: _limit);
      final List<RealEstateHoldModel> previous = append ? state.items : const <RealEstateHoldModel>[];
      emit(state.copyWith(
        items: <RealEstateHoldModel>[...previous, ...fetched.items],
        page: fetched.page,
        total: fetched.total,
        status: ExecutiveHoldsStatus.loaded,
        loadingMore: false,
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ExecutiveHoldsStatus.failure, loadingMore: false, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ExecutiveHoldsStatus.failure, loadingMore: false, message: e.toString()));
    }
  }
}
