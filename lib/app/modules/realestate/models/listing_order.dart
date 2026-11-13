/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

String? _str(dynamic v) => v == null ? null : (v is String ? v : v.toString());

double? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

Map<String, dynamic>? _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

/// A package purchase order (BR-02, BR-05, BR-15).
///
/// Creating an order grants nothing — the entitlement appears at payment.
/// `amount` comes from the catalogue, never the caller, and arrives in
/// rupees (money-edges gate). Wire shape only (plan §12).
class RealEstateOrderModel {
  final String id;
  final String? orderCode;
  final String? vendorId;
  final String? packageId;
  final Map<String, dynamic>? packageSnapshot;
  final double? amount;
  final Map<String, dynamic>? paymentInitiation;
  final String? paymentRef;
  final String? status;
  final DateTime? paidAt;
  final String? entitlementId;
  final DateTime? createdAt;

  const RealEstateOrderModel({
    required this.id,
    this.orderCode,
    this.vendorId,
    this.packageId,
    this.packageSnapshot,
    this.amount,
    this.paymentInitiation,
    this.paymentRef,
    this.status,
    this.paidAt,
    this.entitlementId,
    this.createdAt,
  });

  factory RealEstateOrderModel.fromJson(Map<String, dynamic> json) {
    return RealEstateOrderModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      orderCode: _str(json['orderCode']),
      vendorId: _str(json['vendor']),
      packageId: _str(json['package']),
      packageSnapshot: _map(json['packageSnapshot']),
      amount: _num(json['amount']),
      paymentInitiation: _map(json['paymentInitiation']),
      paymentRef: _str(json['paymentRef']),
      status: _str(json['status']),
      paidAt: _date(json['paidAt']),
      entitlementId: _str(json['entitlement']),
      createdAt: _date(json['createdAt']),
    );
  }
}

/// The vendor pay handoff: the order plus the initiation id (`payLink`) the
/// gateway endpoints take. Amount/status always come from the server.
class RealEstateOrderPayment {
  final RealEstateOrderModel? order;
  final String? payLink;

  const RealEstateOrderPayment({this.order, this.payLink});

  factory RealEstateOrderPayment.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? data = _map(json['data']);
    return RealEstateOrderPayment(
      order: data == null ? null : RealEstateOrderModel.fromJson(data),
      payLink: _str(json['payLink']),
    );
  }
}
