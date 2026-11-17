import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_customer_detail_event.dart';
part 'executive_customer_detail_state.dart';

class ExecutiveCustomerDetailBloc extends Bloc<ExecutiveCustomerDetailEvent, ExecutiveCustomerDetailState> {
  ExecutiveCustomerDetailBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveCustomerDetailState()) {
    on<ExecutiveCustomerDetailLoad>(_onLoad);
    on<ExecutiveCustomerDetailRefreshed>(_onRefreshed);
  }

  final RealEstateExecutiveRepository _repository;

  Future<void> _onLoad(ExecutiveCustomerDetailLoad event, Emitter<ExecutiveCustomerDetailState> emit) async {
    emit(state.copyWith(status: ExecutiveCustomerDetailStatus.loading, customerId: event.customerId, message: ''));
    await _fetch(event.customerId, emit);
  }

  Future<void> _onRefreshed(ExecutiveCustomerDetailRefreshed event, Emitter<ExecutiveCustomerDetailState> emit) async {
    emit(state.copyWith(status: ExecutiveCustomerDetailStatus.loading, message: ''));
    await _fetch(event.customerId, emit);
  }

  Future<void> _fetch(String customerId, Emitter<ExecutiveCustomerDetailState> emit) async {
    try {
      final List<RealEstateLeadModel> collected = <RealEstateLeadModel>[];
      for (int page = 1; page <= 5; page++) {
        final fetched = await _repository.leads(page: page, limit: 20);
        if (fetched.items.isEmpty) break;
        collected.addAll(fetched.items.where((l) => (l.customer?.id ?? l.customerId) == customerId));
        if (fetched.items.length < 20) break;
      }
      emit(state.copyWith(status: ExecutiveCustomerDetailStatus.loaded, leads: collected));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ExecutiveCustomerDetailStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ExecutiveCustomerDetailStatus.failure, message: e.toString()));
    }
  }
}
