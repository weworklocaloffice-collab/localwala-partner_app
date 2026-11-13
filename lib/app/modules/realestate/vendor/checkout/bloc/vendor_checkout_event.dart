/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_checkout_bloc.dart';

abstract class VendorCheckoutEvent {
  const VendorCheckoutEvent();
}

/// Starts checkout for a package code (loads the package row).
class VendorCheckoutStarted extends VendorCheckoutEvent {
  const VendorCheckoutStarted(this.code);

  final String code;
}

/// Confirms the purchase — POST packages/{code}/purchase.
class VendorCheckoutConfirmed extends VendorCheckoutEvent {
  const VendorCheckoutConfirmed();
}

/// Starts (or resumes) payment for the current order.
class VendorCheckoutPayRequested extends VendorCheckoutEvent {
  const VendorCheckoutPayRequested();
}

/// The gateway returned a signed success payload; verify it server-side.
class VendorCheckoutPaymentSucceeded extends VendorCheckoutEvent {
  const VendorCheckoutPaymentSucceeded({
    required this.paymentId,
    required this.orderId,
    required this.signature,
  });

  final String paymentId;
  final String orderId;
  final String signature;
}

/// The gateway closed with an error/user cancel. Not fatal: the order stays.
class VendorCheckoutPaymentFailed extends VendorCheckoutEvent {
  const VendorCheckoutPaymentFailed(this.message);

  final String message;
}

/// Resets to initial (after navigation away).
class VendorCheckoutReset extends VendorCheckoutEvent {
  const VendorCheckoutReset();
}
