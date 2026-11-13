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

/// A recorded sale (BR-13: only a sale moves availability to SOLD).
///
/// `saleValue` arrives in rupees (money-edges gate). Wire shape only.
class RealEstateSaleModel {
  final String id;
  final String? saleCode;
  final String? propertyId;
  final RealEstatePropertyRef? property;
  final String? customerId;
  final RealEstateCustomerRef? customer;
  final String? vendorId;
  final String? leadId;
  final String? holdId;
  final double? holdPrincipalApplied;
  final double? saleValue;
  final String? transactionType;
  final String? status;
  final DateTime? soldAt;
  final String? cancellationReason;
  final DateTime? createdAt;

  const RealEstateSaleModel({
    required this.id,
    this.saleCode,
    this.propertyId,
    this.property,
    this.customerId,
    this.customer,
    this.vendorId,
    this.leadId,
    this.holdId,
    this.holdPrincipalApplied,
    this.saleValue,
    this.transactionType,
    this.status,
    this.soldAt,
    this.cancellationReason,
    this.createdAt,
  });

  factory RealEstateSaleModel.fromJson(Map<String, dynamic> json) {
    return RealEstateSaleModel(
      id: _idOf(json),
      saleCode: _str(json['saleCode']),
      propertyId: _refId(json['property']) ?? RealEstatePropertyRef.tryParse(json['property'])?.id,
      property: RealEstatePropertyRef.tryParse(json['property']),
      customerId: _refId(json['customer']) ?? RealEstateCustomerRef.tryParse(json['customer'])?.id,
      customer: RealEstateCustomerRef.tryParse(json['customer']),
      vendorId: _str(json['vendor']),
      leadId: _str(json['lead']),
      holdId: _str(json['hold']),
      holdPrincipalApplied: _num(json['holdPrincipalApplied']),
      saleValue: _num(json['saleValue']),
      transactionType: _str(json['transactionType']),
      status: _str(json['status']),
      soldAt: _date(json['soldAt']),
      cancellationReason: _str(json['cancellationReason']),
      createdAt: _date(json['createdAt']),
    );
  }
}
