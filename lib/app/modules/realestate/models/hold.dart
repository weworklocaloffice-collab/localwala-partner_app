/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:partner/app/modules/realestate/models/lead.dart';

String _idOf(Map<String, dynamic> json) => (json['_id'] ?? json['id'])?.toString() ?? '';

String? _str(dynamic v) => v == null ? null : (v is String ? v : v.toString());

/// An id that may arrive raw or inside a populated map (see lead.dart).
String? _refId(dynamic v) => v is Map ? null : _str(v);

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

/// A property hold: customer money in trust (BR-12, BR-13).
///
/// `principal` is a LIABILITY, never revenue; `serviceFee` is platform
/// revenue earned at activation. Amounts arrive in rupees (money-edges
/// gate). Wire shape only (plan §12).
class RealEstateHoldModel {
  final String id;
  final String? holdCode;
  final String? propertyId;
  final RealEstatePropertyRef? property;
  final String? customerId;
  final RealEstateCustomerRef? customer;
  final String? leadId;
  final Map<String, dynamic>? policySnapshot;
  final double? principal;
  final double? serviceFee;
  final double? total;
  final String? status;
  final DateTime? placedAt;
  final DateTime? expiresAt;
  final DateTime? activatedAt;
  final String? convertedSaleId;
  final String? cancellationReason;
  final DateTime? createdAt;

  const RealEstateHoldModel({
    required this.id,
    this.holdCode,
    this.propertyId,
    this.property,
    this.customerId,
    this.customer,
    this.leadId,
    this.policySnapshot,
    this.principal,
    this.serviceFee,
    this.total,
    this.status,
    this.placedAt,
    this.expiresAt,
    this.activatedAt,
    this.convertedSaleId,
    this.cancellationReason,
    this.createdAt,
  });

  factory RealEstateHoldModel.fromJson(Map<String, dynamic> json) {
    return RealEstateHoldModel(
      id: _idOf(json),
      holdCode: _str(json['holdCode']),
      propertyId: _refId(json['property']) ?? RealEstatePropertyRef.tryParse(json['property'])?.id,
      property: RealEstatePropertyRef.tryParse(json['property']),
      customerId: _refId(json['customer']) ?? RealEstateCustomerRef.tryParse(json['customer'])?.id,
      customer: RealEstateCustomerRef.tryParse(json['customer']),
      leadId: _str(json['lead']),
      policySnapshot: _map(json['policySnapshot']),
      principal: _num(json['principal']),
      serviceFee: _num(json['serviceFee']),
      total: _num(json['total']),
      status: _str(json['status']),
      placedAt: _date(json['placedAt']),
      expiresAt: _date(json['expiresAt']),
      activatedAt: _date(json['activatedAt']),
      convertedSaleId: _str(json['convertedSale']),
      cancellationReason: _str(json['cancellationReason']),
      createdAt: _date(json['createdAt']),
    );
  }
}
