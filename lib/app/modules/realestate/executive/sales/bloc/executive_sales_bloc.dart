import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/sale.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_sales_event.dart';
part 'executive_sales_state.dart';

class ExecutiveSalesBloc extends Bloc<ExecutiveSalesEvent, ExecutiveSalesState> {
  ExecutiveSalesBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveSalesState()) {
    on<ExecutiveSalesLoad>(_onLoad);
    on<ExecutiveSalesNextPage>(_onNextPage);
    on<ExecutiveSalesRefreshed>(_onRefreshed);
  }

  static const int _limit = 20;

  final RealEstateExecutiveRepository _repository;

  Future<void> _onLoad(ExecutiveSalesLoad event, Emitter<ExecutiveSalesState> emit) async {
    emit(state.copyWith(status: ExecutiveSalesStatus.loading, message: ''));
    await _loadPage(emit, 1, append: false);
  }

  Future<void> _onNextPage(ExecutiveSalesNextPage event, Emitter<ExecutiveSalesState> emit) async {
    if (!state.hasMore || state.loadingMore || state.status == ExecutiveSalesStatus.loading) return;
    emit(state.copyWith(loadingMore: true));
    await _loadPage(emit, state.page + 1, append: true);
  }

  Future<void> _onRefreshed(ExecutiveSalesRefreshed event, Emitter<ExecutiveSalesState> emit) async {
    emit(state.copyWith(status: ExecutiveSalesStatus.loading, message: ''));
    await _loadPage(emit, 1, append: false);
  }

  Future<void> _loadPage(Emitter<ExecutiveSalesState> emit, int page, {required bool append}) async {
    try {
      final fetched = await _repository.sales(page: page, limit: _limit);
      final List<RealEstateSaleModel> previous = append ? state.items : const <RealEstateSaleModel>[];
      emit(state.copyWith(
        items: <RealEstateSaleModel>[...previous, ...fetched.items],
        page: fetched.page,
        total: fetched.total,
        status: ExecutiveSalesStatus.loaded,
        loadingMore: false,
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ExecutiveSalesStatus.failure, loadingMore: false, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ExecutiveSalesStatus.failure, loadingMore: false, message: e.toString()));
    }
  }
}
