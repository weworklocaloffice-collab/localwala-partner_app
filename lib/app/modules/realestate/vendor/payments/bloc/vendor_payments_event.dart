/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_payments_bloc.dart';

abstract class VendorPaymentsEvent {
  const VendorPaymentsEvent();
}

/// Loads the order history (the payment trail).
class VendorPaymentsLoadRequested extends VendorPaymentsEvent {
  const VendorPaymentsLoadRequested();
}

/// Reloads the order history.
class VendorPaymentsRefreshed extends VendorPaymentsEvent {
  const VendorPaymentsRefreshed();
}

/// Cancels a pending order (reason optional).
class VendorPaymentCancelRequested extends VendorPaymentsEvent {
  const VendorPaymentCancelRequested(this.orderId);

  final String orderId;
}

/// Starts (or resumes) the gateway handoff for an unpaid order.
class VendorPaymentPayRequested extends VendorPaymentsEvent {
  const VendorPaymentPayRequested(this.orderId);

  final String orderId;
}

/// Signed gateway payload; the API verifies it before granting anything.
class VendorPaymentSucceeded extends VendorPaymentsEvent {
  const VendorPaymentSucceeded({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });

  final String paymentId;
  final String orderId;
  final String signature;
}

/// Gateway error/user cancel. The list stays usable.
class VendorPaymentFailed extends VendorPaymentsEvent {
  const VendorPaymentFailed(this.message);

  final String message;
}
