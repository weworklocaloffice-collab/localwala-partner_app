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
import 'package:partner/app/modules/realestate/models/listing_package.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

part 'vendor_checkout_event.dart';
part 'vendor_checkout_state.dart';

/// Package checkout (plan §11.3, BR-02).
///
/// Confirming POSTs `packages/{code}/purchase` through the existing
/// payment stack — the entitlement appears at payment, never at order
/// creation. The order's `paymentInitiation` carries the gateway handoff.
class VendorCheckoutBloc
    extends Bloc<VendorCheckoutEvent, VendorCheckoutState> {
  VendorCheckoutBloc({RealEstateVendorRepository? repository})
    : _repository = repository ?? RealEstateVendorRepository(),
      super(const VendorCheckoutState()) {
    on<VendorCheckoutStarted>(_onStarted);
    on<VendorCheckoutConfirmed>(_onConfirmed);
    on<VendorCheckoutPayRequested>(_onPayRequested);
    on<VendorCheckoutPaymentSucceeded>(_onPaymentSucceeded);
    on<VendorCheckoutPaymentFailed>(_onPaymentFailed);
    on<VendorCheckoutReset>(_onReset);
  }

  final RealEstateVendorRepository _repository;

  Future<void> _onStarted(
    VendorCheckoutStarted event,
    Emitter<VendorCheckoutState> emit,
  ) async {
    emit(state.copyWith(status: VendorCheckoutStatus.loading, message: ''));
    try {
      final RealEstatePackageModel? package = await _repository.package(
        event.code,
      );
      if (package == null) {
        emit(
          state.copyWith(
            status: VendorCheckoutStatus.failure,
            message: 'Package not found',
          ),
        );
        return;
      }
      emit(
        VendorCheckoutState(
          status: VendorCheckoutStatus.done,
          package: package,
        ),
      );
    } on RealEstateApiException catch (e) {
      emit(
        state.copyWith(
          status: VendorCheckoutStatus.failure,
          message: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: VendorCheckoutStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onConfirmed(
    VendorCheckoutConfirmed event,
    Emitter<VendorCheckoutState> emit,
  ) async {
    final String? code = state.package?.code;
    if (code == null || code.isEmpty) return;
    emit(state.copyWith(status: VendorCheckoutStatus.confirming, message: ''));
    try {
      final RealEstateOrderModel? order = await _repository.purchasePackage(
        code,
      );
      emit(
        state.copyWith(
          status: VendorCheckoutStatus.done,
          order: order,
          clearPayment: true,
          paymentError: '',
        ),
      );
    } on RealEstateApiException catch (e) {
      emit(
        state.copyWith(
          status: VendorCheckoutStatus.failure,
          message: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: VendorCheckoutStatus.failure,
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> _onPayRequested(
    VendorCheckoutPayRequested event,
    Emitter<VendorCheckoutState> emit,
  ) async {
    final RealEstateOrderModel? order = state.order;
    if (order == null || order.id.isEmpty || order.status == 'PAID') return;
    emit(
      state.copyWith(
        status: VendorCheckoutStatus.paying,
        message: '',
        clearPayment: true,
        paymentError: '',
      ),
    );
    try {
      final RealEstateOrderPayment? payment = await _repository.payOrder(
        order.id,
      );
      final String? link = payment?.payLink;
      if (link == null || link.isEmpty) {
        throw const RealEstateApiException('Could not start the payment');
      }
      final Map<String, dynamic> options = await _repository.paymentOrder(link);
      emit(
        state.copyWith(
          status: VendorCheckoutStatus.done,
          order: payment?.order ?? order,
          payLink: link,
          paymentOptions: options,
          paymentError: '',
        ),
      );
    } on RealEstateApiException catch (e) {
      emit(
        state.copyWith(
          status: VendorCheckoutStatus.done,
          clearPayment: true,
          paymentError: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: VendorCheckoutStatus.done,
          clearPayment: true,
          paymentError: e.toString(),
        ),
      );
    }
  }

  Future<void> _onPaymentSucceeded(
    VendorCheckoutPaymentSucceeded event,
    Emitter<VendorCheckoutState> emit,
  ) async {
    final String? link = state.payLink;
    final RealEstateOrderModel? order = state.order;
    if (link == null || order == null) return;
    emit(
      state.copyWith(status: VendorCheckoutStatus.verifying, paymentError: ''),
    );
    try {
      await _repository.verifyPayment(
        link,
        paymentId: event.paymentId,
        orderId: event.orderId,
        signature: event.signature,
      );
      final RealEstateOrderModel? fresh = await _repository.order(order.id);
      emit(
        state.copyWith(
          status: VendorCheckoutStatus.done,
          order: fresh ?? order,
          clearPayment: true,
          paymentError: '',
        ),
      );
    } on RealEstateApiException catch (e) {
      final RealEstateOrderModel? fresh = await _reloadOrder(order);
      emit(
        state.copyWith(
          status: VendorCheckoutStatus.done,
          order: fresh,
          clearPayment: true,
          paymentError: fresh?.status == 'PAID' ? '' : e.message,
        ),
      );
    } catch (e) {
      final RealEstateOrderModel? fresh = await _reloadOrder(order);
      emit(
        state.copyWith(
          status: VendorCheckoutStatus.done,
          order: fresh,
          clearPayment: true,
          paymentError: fresh?.status == 'PAID' ? '' : e.toString(),
        ),
      );
    }
  }

  Future<RealEstateOrderModel?> _reloadOrder(RealEstateOrderModel order) async {
    try {
      return await _repository.order(order.id);
    } catch (_) {
      return null;
    }
  }

  void _onPaymentFailed(
    VendorCheckoutPaymentFailed event,
    Emitter<VendorCheckoutState> emit,
  ) {
    emit(
      state.copyWith(
        status: VendorCheckoutStatus.done,
        clearPayment: true,
        paymentError: event.message.isEmpty
            ? 'Payment was not completed'
            : event.message,
      ),
    );
  }

  void _onReset(VendorCheckoutReset event, Emitter<VendorCheckoutState> emit) {
    emit(const VendorCheckoutState());
  }
}
