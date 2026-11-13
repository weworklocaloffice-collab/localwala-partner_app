/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_payments_bloc.dart';

enum VendorPaymentsStatus { initial, loading, loaded, failure }

class VendorPaymentsState {
  final VendorPaymentsStatus status;
  final List<RealEstateOrderModel> orders;
  final int total;
  final String message;

  /// Order currently being handed to the gateway (button spinner).
  final String? payingOrderId;

  /// Initiation id + gateway options prepared by the pay endpoint.
  final String? payLink;
  final Map<String, dynamic>? paymentOptions;

  /// Non-fatal payment error, kept separate from a failed list load.
  final String paymentError;

  const VendorPaymentsState({
    this.status = VendorPaymentsStatus.initial,
    this.orders = const <RealEstateOrderModel>[],
    this.total = 0,
    this.message = '',
    this.payingOrderId,
    this.payLink,
    this.paymentOptions,
    this.paymentError = '',
  });

  VendorPaymentsState copyWith({
    VendorPaymentsStatus? status,
    List<RealEstateOrderModel>? orders,
    int? total,
    String? message,
    String? payingOrderId,
    String? payLink,
    Map<String, dynamic>? paymentOptions,
    String? paymentError,
    bool clearPayment = false,
    bool clearPaying = false,
  }) {
    return VendorPaymentsState(
      status: status ?? this.status,
      orders: orders ?? this.orders,
      total: total ?? this.total,
      message: message ?? this.message,
      payingOrderId: clearPaying ? null : (payingOrderId ?? this.payingOrderId),
      payLink: clearPayment ? null : (payLink ?? this.payLink),
      paymentOptions: clearPayment
          ? null
          : (paymentOptions ?? this.paymentOptions),
      paymentError: paymentError ?? this.paymentError,
    );
  }
}
