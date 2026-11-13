/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/commission.dart';
import 'package:partner/app/modules/realestate/models/loan.dart';
import 'package:partner/app/modules/realestate/models/sale.dart';
import 'package:partner/app/modules/realestate/models/settlement.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_earnings_event.dart';
part 'executive_earnings_state.dart';

class ExecutiveEarningsBloc extends Bloc<ExecutiveEarningsEvent, ExecutiveEarningsState> {
  ExecutiveEarningsBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveEarningsState()) {
    on<ExecutiveEarningsLoad>(_onLoad);
    on<ExecutiveEarningsRefreshed>(_onLoad);
  }

  final RealEstateExecutiveRepository _repository;

  Future<void> _onLoad(
    ExecutiveEarningsEvent event,
    Emitter<ExecutiveEarningsState> emit,
  ) async {
    emit(state.copyWith(status: ExecutiveEarningsStatus.loading, message: ''));
    try {
      final List<dynamic> results = await Future.wait(<Future<dynamic>>[
        _repository.commissions(page: 1, limit: 50),
        _repository.settlements(page: 1, limit: 50),
        _repository.loans(page: 1, limit: 50),
        _repository.sales(page: 1, limit: 50),
      ]);
      emit(
        state.copyWith(
          status: ExecutiveEarningsStatus.loaded,
          commissions: results[0] as RealEstatePage<RealEstateCommissionModel>,
          settlements: results[1] as RealEstatePage<RealEstateSettlementModel>,
          loans: results[2] as RealEstatePage<RealEstateLoanModel>,
          sales: results[3] as RealEstatePage<RealEstateSaleModel>,
        ),
      );
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ExecutiveEarningsStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ExecutiveEarningsStatus.failure, message: e.toString()));
    }
  }
}
