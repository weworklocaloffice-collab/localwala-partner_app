import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/loan.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_loan_status_event.dart';
part 'executive_loan_status_state.dart';

class ExecutiveLoanStatusBloc extends Bloc<ExecutiveLoanStatusEvent, ExecutiveLoanStatusState> {
  ExecutiveLoanStatusBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveLoanStatusState()) {
    on<ExecutiveLoanStatusLoad>(_onLoad);
    on<ExecutiveLoanStatusNextPage>(_onNextPage);
    on<ExecutiveLoanStatusRefreshed>(_onRefreshed);
  }

  static const int _limit = 20;

  final RealEstateExecutiveRepository _repository;

  Future<void> _onLoad(ExecutiveLoanStatusLoad event, Emitter<ExecutiveLoanStatusState> emit) async {
    emit(state.copyWith(status: ExecutiveLoanStatusStateStatus.loading, message: ''));
    await _loadPage(emit, 1, append: false);
  }

  Future<void> _onNextPage(ExecutiveLoanStatusNextPage event, Emitter<ExecutiveLoanStatusState> emit) async {
    if (!state.hasMore || state.loadingMore || state.status == ExecutiveLoanStatusStateStatus.loading) return;
    emit(state.copyWith(loadingMore: true));
    await _loadPage(emit, state.page + 1, append: true);
  }

  Future<void> _onRefreshed(ExecutiveLoanStatusRefreshed event, Emitter<ExecutiveLoanStatusState> emit) async {
    emit(state.copyWith(status: ExecutiveLoanStatusStateStatus.loading, message: ''));
    await _loadPage(emit, 1, append: false);
  }

  Future<void> _loadPage(Emitter<ExecutiveLoanStatusState> emit, int page, {required bool append}) async {
    try {
      final fetched = await _repository.loans(page: page, limit: _limit);
      final List<RealEstateLoanModel> previous = append ? state.items : const <RealEstateLoanModel>[];
      emit(state.copyWith(
        items: <RealEstateLoanModel>[...previous, ...fetched.items],
        page: fetched.page,
        total: fetched.total,
        status: ExecutiveLoanStatusStateStatus.loaded,
        loadingMore: false,
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ExecutiveLoanStatusStateStatus.failure, loadingMore: false, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ExecutiveLoanStatusStateStatus.failure, loadingMore: false, message: e.toString()));
    }
  }
}
