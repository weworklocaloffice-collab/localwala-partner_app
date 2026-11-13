/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/app/modules/realestate/repository/executive_repository.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'executive_customers_event.dart';
part 'executive_customers_state.dart';

/// Customers derived from this executive's assigned leads.
///
/// There is no `GET /executive/customers` endpoint — the customer rows
/// on leads are the source of truth. The bloc pages through leads
/// (up to five pages) and dedupes by customer id. Tapping a customer
/// shows which leads link to them.
class ExecutiveCustomersBloc extends Bloc<ExecutiveCustomersEvent, ExecutiveCustomersState> {
  ExecutiveCustomersBloc({RealEstateExecutiveRepository? repository})
      : _repository = repository ?? RealEstateExecutiveRepository(),
        super(const ExecutiveCustomersState()) {
    on<ExecutiveCustomersLoad>(_onLoad);
    on<ExecutiveCustomersRefreshed>(_onRefreshed);
  }

  static const int _maxPages = 5;
  static const int _limit = 20;

  final RealEstateExecutiveRepository _repository;

  Future<void> _onLoad(ExecutiveCustomersLoad event, Emitter<ExecutiveCustomersState> emit) async {
    emit(state.copyWith(status: ExecutiveCustomersStatus.loading, message: ''));
    await _collect(emit);
  }

  Future<void> _onRefreshed(ExecutiveCustomersRefreshed event, Emitter<ExecutiveCustomersState> emit) async {
    emit(state.copyWith(status: ExecutiveCustomersStatus.loading, message: ''));
    await _collect(emit);
  }

  Future<void> _collect(Emitter<ExecutiveCustomersState> emit) async {
    try {
      final Map<String, RealEstateCustomerRef> byId = <String, RealEstateCustomerRef>{};
      final Map<String, List<RealEstateLeadModel>> leadsByCustomer = <String, List<RealEstateLeadModel>>{};
      for (int page = 1; page <= _maxPages; page++) {
        final RealEstatePage<RealEstateLeadModel> fetched = await _repository.leads(page: page, limit: _limit);
        if (fetched.items.isEmpty) break;
        for (final RealEstateLeadModel lead in fetched.items) {
          final RealEstateCustomerRef? c = lead.customer;
          final String key = c?.id ?? lead.customerId ?? '';
          if (key.isEmpty) continue;
          byId.putIfAbsent(key, () => c ?? RealEstateCustomerRef(id: key));
          leadsByCustomer.putIfAbsent(key, () => <RealEstateLeadModel>[]).add(lead);
        }
        if (fetched.items.length < _limit) break;
      }
      final List<RealEstateCustomerRef> customers = byId.values.toList()
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
      emit(state.copyWith(
        customers: customers,
        leadsByCustomer: leadsByCustomer,
        status: ExecutiveCustomersStatus.loaded,
      ));
    } on RealEstateApiException catch (e) {
      emit(state.copyWith(status: ExecutiveCustomersStatus.failure, message: e.message));
    } catch (e) {
      emit(state.copyWith(status: ExecutiveCustomersStatus.failure, message: e.toString()));
    }
  }
}
