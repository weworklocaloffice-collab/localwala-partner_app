/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 *
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

/// Jhatka money boundary, client side.
///
/// The API speaks **rupees** on order documents (`moneyField` getters) and
/// **paise** on confirmations (fields whose names end in `Paise`). Two shipped
/// 100x bugs came from mixing the two, so every crossing goes through here —
/// never a bare `/ 100` or `* 100` at a call site.
library;

/// Paise to a display string: 40000 -> "Rs 400.00".
///
/// Takes `num` because lean reads decode from JSON, where whole numbers may
/// still arrive typed loosely. Rounds to the nearest paise.
String formatPaise(num paise) {
  final int p = paise.round();
  final bool negative = p < 0;
  final int abs = p.abs();
  final String rupees = (abs ~/ 100).toString();
  final String tail = (abs % 100).toString().padLeft(2, '0');
  return '${negative ? '-' : ''}Rs $rupees.$tail';
}

/// Rupees (as the API returns them) to a display string.
String formatRupees(num rupees) {
  return formatPaise((rupees * 100).round());
}

/// Rupees from the API to integer paise for local arithmetic.
int rupeesToPaise(num rupees) => (rupees * 100).round();

/// Quantity to grams. Mirrors the server's `toGrams` for the units a
/// weighing screen can produce. Returns null when unconvertible.
int? toGrams(num value, String unit) {
  switch (unit.toUpperCase()) {
    case 'GRAM':
      return value.round();
    case 'KG':
      return (value * 1000).round();
    default:
      return null;
  }
}

/// Estimated line amount in paise, mirroring the server floor:
/// `requestedGrams x unitPricePaise / 1000`, floored.
int estimatedLinePaise({
  required int requestedGrams,
  required int unitPricePaise,
}) {
  return (requestedGrams * unitPricePaise) ~/ 1000;
}

/// Client-side VW-01: the customer is never charged above the estimate.
/// The server enforces it; the screen refuses to send what it knows is wrong.
bool withinEstimate({required int finalPaise, required int estimatedPaise}) {
  return finalPaise <= estimatedPaise;
}
