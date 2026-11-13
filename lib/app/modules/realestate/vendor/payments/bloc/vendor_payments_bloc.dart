/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:partner/app/modules/realestate/models/listing_order.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'vendor_payments_event.dart';
part 'vendor_payments_state.dart';

/// Payment history (plan §11.3).
///
/// Orders flow through the existing payment stack — this screen is the
/// trail (order code, amount, status), never a second payment path.
/// Cancelling is allowed while the order is still pending.
class VendorPaymentsBloc
    extends Bloc<VendorPaymentsEvent, VendorPaymentsState> {
  VendorPaymentsBloc({RealEstateVendorRepository? repository})
    : _repository = repository ?? RealEstateVendorRepository(),
      super(const VendorPaymentsState()) {
    on<VendorPaymentsLoadRequested>(_onLoadRequested);
    on<VendorPaymentsRefreshed>(_onRefreshed);
    on<VendorPaymentCancelRequested>(_onCancelRequested);
    on<VendorPaymentPayRequested>(_onPayRequested);
    on<VendorPaymentSucceeded>(_onPaymentSucceeded);
    on<VendorPaymentFailed>(_onPaymentFailed);
  }

  final RealEstateVendorRepository _repository;

  Future<void> _load(Emitter<VendorPaymentsState> emit) async {
    try {
      final RealEstatePage<RealEstateOrderModel> page = await _repository
          .orders(limit: 20);
      emit(
        state.copyWith(
          status: VendorPaymentsStatus.loaded,
          orders: page.items,
          total: page.total,
        ),
      );
    } on RealEstateApiException catch (e) {
      emit(
        state.copyWith(
          status: VendorPaymentsStatus.failure,
          message: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: VendorPaymentsStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadRequested(
    VendorPaymentsLoadRequested event,
    Emitter<VendorPaymentsState> emit,
  ) async {
    emit(state.copyWith(status: VendorPaymentsStatus.loading, message: ''));
    await _load(emit);
  }

  Future<void> _onRefreshed(
    VendorPaymentsRefreshed event,
    Emitter<VendorPaymentsState> emit,
  ) async {
    emit(state.copyWith(status: VendorPaymentsStatus.loading, message: ''));
    await _load(emit);
  }

  Future<void> _onCancelRequested(
    VendorPaymentCancelRequested event,
    Emitter<VendorPaymentsState> emit,
  ) async {
    try {
      await _repository.cancelOrder(event.orderId);
      await _load(emit);
    } on RealEstateApiException catch (e) {
      emit(
        state.copyWith(
          status: VendorPaymentsStatus.failure,
          message: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: VendorPaymentsStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onPayRequested(
    VendorPaymentPayRequested event,
    Emitter<VendorPaymentsState> emit,
  ) async {
    emit(
      state.copyWith(
        payingOrderId: event.orderId,
        clearPayment: true,
        paymentError: '',
      ),
    );
    try {
      final RealEstateOrderPayment? payment = await _repository.payOrder(
        event.orderId,
      );
      final String? link = payment?.payLink;
      if (link == null || link.isEmpty) {
        throw const RealEstateApiException('Could not start the payment');
      }
      final Map<String, dynamic> options = await _repository.paymentOrder(link);
      final List<RealEstateOrderModel> orders = payment?.order == null
          ? state.orders
          : state.orders
                .map(
                  (RealEstateOrderModel o) =>
                      o.id == event.orderId ? payment!.order! : o,
                )
                .toList();
      emit(
        state.copyWith(
          orders: orders,
          payLink: link,
          paymentOptions: options,
          paymentError: '',
        ),
      );
    } on RealEstateApiException catch (e) {
      emit(
        state.copyWith(
          clearPayment: true,
          clearPaying: true,
          paymentError: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          clearPayment: true,
          clearPaying: true,
          paymentError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onPaymentSucceeded(
    VendorPaymentSucceeded event,
    Emitter<VendorPaymentsState> emit,
  ) async {
    final String? link = state.payLink;
    if (link == null) return;
    final String? localOrderId = state.payingOrderId;
    emit(state.copyWith(paymentError: ''));
    try {
      await _repository.verifyPayment(
        link,
        paymentId: event.paymentId,
        orderId: event.orderId,
        signature: event.signature,
      );
      await _load(emit);
      emit(
        state.copyWith(clearPayment: true, clearPaying: true, paymentError: ''),
      );
    } on RealEstateApiException catch (e) {
      await _load(emit);
      emit(
        state.copyWith(
          clearPayment: true,
          clearPaying: true,
          paymentError: _isPaid(localOrderId) ? '' : e.message,
        ),
      );
    } catch (e) {
      await _load(emit);
      emit(
        state.copyWith(
          clearPayment: true,
          clearPaying: true,
          paymentError: _isPaid(localOrderId) ? '' : e.toString(),
        ),
      );
    }
  }

  bool _isPaid(String? orderId) {
    if (orderId == null) return false;
    return state.orders.any(
      (RealEstateOrderModel o) => o.id == orderId && o.status == 'PAID',
    );
  }

  void _onPaymentFailed(
    VendorPaymentFailed event,
    Emitter<VendorPaymentsState> emit,
  ) {
    emit(
      state.copyWith(
        clearPayment: true,
        clearPaying: true,
        paymentError: event.message.isEmpty
            ? 'Payment was not completed'
            : event.message,
      ),
    );
  }
}
