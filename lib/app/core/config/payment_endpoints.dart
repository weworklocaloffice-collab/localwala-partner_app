/// Platform payment routes shared by commerce verticals.
///
/// The payment initiation itself is created by the owning vertical. These
/// routes only create the gateway order and verify Razorpay's signed response.
class PaymentEndpoints {
  const PaymentEndpoints._();

  static const String makePayment = 'v1/public/payments/makePayment/{id}';
  static const String verifyPayment = 'v1/public/payments/paid_success/{id}';

  static String resolve(String template, Map<String, String> values) {
    return template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (Match match) {
      final String? value = values[match.group(1)];
      if (value == null || value.isEmpty) {
        throw ArgumentError('Missing "${match.group(1)}" for payment route $template');
      }
      return Uri.encodeComponent(value);
    });
  }
}
