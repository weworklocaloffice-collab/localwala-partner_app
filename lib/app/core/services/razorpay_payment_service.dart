import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Shared native Razorpay checkout adapter.
///
/// Each vertical owns its payment initiation, amount, and activation policy;
/// this class only opens checkout and forwards gateway callbacks.
class RazorpayPaymentService {
  Razorpay? _razorpay;
  void Function(String?, String?, String?)? _onSuccess;
  void Function(String)? _onFailure;

  void open(
    Map<String, dynamic> options, {
    required void Function(String? paymentId, String? orderId, String? signature)
        onSuccess,
    required void Function(String message) onFailure,
  }) {
    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _razorpay ??= Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, (dynamic response) {
        final PaymentSuccessResponse success = response as PaymentSuccessResponse;
        _onSuccess?.call(success.paymentId, success.orderId, success.signature);
      })
      ..on(Razorpay.EVENT_PAYMENT_ERROR, (dynamic response) {
        final PaymentFailureResponse failure = response as PaymentFailureResponse;
        _onFailure?.call(failure.message ?? 'Payment was not completed');
      });
    _razorpay!.open(options);
  }

  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
    _onSuccess = null;
    _onFailure = null;
  }
}
