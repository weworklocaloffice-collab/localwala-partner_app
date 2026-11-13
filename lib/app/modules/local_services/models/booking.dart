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

/// Local Services booking. Money arrives in rupees on every edge
/// (moneyField getters); no paise conversion anywhere in this folder.
class LsBooking {
  final String id;
  final String code;
  final String status;
  final String bookingMode;
  final double labourAmount;
  final double partsAmount;
  final String? scheduledAt;

  const LsBooking({
    required this.id,
    required this.code,
    required this.status,
    required this.bookingMode,
    required this.labourAmount,
    required this.partsAmount,
    this.scheduledAt,
  });

  static double _num(dynamic v) =>
      v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  factory LsBooking.fromJson(Map<String, dynamic> json) => LsBooking(
        id: '${json['_id'] ?? json['id'] ?? ''}',
        code: '${json['bookingCode'] ?? ''}',
        status: '${json['status'] ?? ''}',
        bookingMode: '${json['bookingMode'] ?? ''}',
        labourAmount: _num(json['labourAmount']),
        partsAmount: _num(json['partsAmount']),
        scheduledAt: json['scheduledAt']?.toString() ?? json['startAt']?.toString(),
      );

  /// Actions the server permits from the current status (mirrors
  /// BOOKING_TRANSITIONS; the server allow-lists again, this is display only).
  List<String> get actions {
    switch (status) {
      case 'PENDING_PROVIDER':
        return <String>['ACCEPTED', 'CANCELLED'];
      case 'ACCEPTED':
        return <String>['CONFIRMED', 'CANCELLED'];
      case 'CONFIRMED':
        return <String>['IN_PROGRESS', 'CANCELLED', 'NO_SHOW'];
      case 'IN_PROGRESS':
        return <String>['COMPLETED', 'DISPUTED'];
      default:
        return const <String>[];
    }
  }
}
