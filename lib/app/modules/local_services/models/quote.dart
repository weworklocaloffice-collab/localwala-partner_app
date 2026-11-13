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

/// A quotation on a booking. Amounts in rupees; only the latest SUBMITTED
/// revision is actionable — history is display-only.
class LsQuote {
  final String id;
  final double labourAmount;
  final double partsAmount;
  final String status;
  final String? expiresAt;

  const LsQuote({
    required this.id,
    required this.labourAmount,
    required this.partsAmount,
    required this.status,
    this.expiresAt,
  });

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  factory LsQuote.fromJson(Map<String, dynamic> json) => LsQuote(
        id: '${json['_id'] ?? json['id'] ?? ''}',
        labourAmount: _num(json['labourAmount']),
        partsAmount: _num(json['partsAmount']),
        status: '${json['status'] ?? ''}',
        expiresAt: json['expiresAt']?.toString(),
      );
}
