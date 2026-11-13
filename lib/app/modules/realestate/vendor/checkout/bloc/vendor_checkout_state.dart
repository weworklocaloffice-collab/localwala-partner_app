/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_checkout_bloc.dart';

enum VendorCheckoutStatus {
  initial,
  loading,
  confirming,
  paying,
  verifying,
  done,
  failure,
}

class VendorCheckoutState {
  final VendorCheckoutStatus status;
  final RealEstatePackageModel? package;
  final RealEstateOrderModel? order;
  final String message;

  /// Initiation id from the pay endpoint. The view opens the gateway only
  /// once per link; a rebuild must not launch a second checkout.
  final String? payLink;

  /// `makePayment` payload (gateway key, order id, paise amount, prefill).
  final Map<String, dynamic>? paymentOptions;

  /// Gateway/verification error kept separate from the fatal [message], so a
  /// failed payment does not replace the order screen with the load error.
  final String paymentError;

  const VendorCheckoutState({
    this.status = VendorCheckoutStatus.initial,
    this.package,
    this.order,
    this.message = '',
    this.payLink,
    this.paymentOptions,
    this.paymentError = '',
  });

  VendorCheckoutState copyWith({
    VendorCheckoutStatus? status,
    RealEstatePackageModel? package,
    RealEstateOrderModel? order,
    String? message,
    String? payLink,
    Map<String, dynamic>? paymentOptions,
    String? paymentError,
    bool clearPayment = false,
  }) {
    return VendorCheckoutState(
      status: status ?? this.status,
      package: package ?? this.package,
      order: order ?? this.order,
      message: message ?? this.message,
      payLink: clearPayment ? null : (payLink ?? this.payLink),
      paymentOptions: clearPayment
          ? null
          : (paymentOptions ?? this.paymentOptions),
      paymentError: paymentError ?? this.paymentError,
    );
  }
}
