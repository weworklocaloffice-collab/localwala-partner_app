/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/app/modules/realestate/models/visit_request.dart';

String _idOf(Map<String, dynamic> json) => (json['_id'] ?? json['id'])?.toString() ?? '';

String? _str(dynamic v) => v == null ? null : (v is String ? v : v.toString());

/// An id that may arrive raw or inside a populated map (see lead.dart).
String? _refId(dynamic v) => v is Map ? null : _str(v);

/// The executive arrives raw (list rows) or populated with name/mobile
/// (detail joins). A populated map must never stringify into the id.
String? _execId(dynamic v) =>
    v is Map ? (v['_id'] ?? v['id'])?.toString() : _str(v);

String? _execName(dynamic v) => v is Map ? v['name']?.toString() : null;

String? _execMobile(dynamic v) => v is Map ? v['mobile']?.toString() : null;

int _int(dynamic v, [int dflt = 200]) {
  if (v == null) return dflt;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? dflt;
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

Map<String, dynamic>? _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

/// A scheduled site visit (BR-08).
///
/// The vendor sees a read-only schedule; the executive works the visit
/// through accept → check-in → complete. Wire shape only (plan §12).
class RealEstateVisitModel {
  final String id;
  final String? propertyId;
  final RealEstatePropertyRef? property;
  final String? customerId;
  final RealEstateCustomerRef? customer;
  final String? leadId;
  final RealEstateLeadRef? lead;
  final String? executiveId;
  final String? executiveName;
  final String? executiveMobile;
  final String? requestId;
  final String? status;
  final DateTime? scheduledAt;
  final int checkInRadiusMeters;
  final Map<String, dynamic>? checkIn;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String? cancellationReason;
  final String? notes;
  final DateTime? createdAt;

  const RealEstateVisitModel({
    required this.id,
    this.propertyId,
    this.property,
    this.customerId,
    this.customer,
    this.leadId,
    this.lead,
    this.executiveId,
    this.executiveName,
    this.executiveMobile,
    this.requestId,
    this.status,
    this.scheduledAt,
    this.checkInRadiusMeters = 200,
    this.checkIn,
    this.startedAt,
    this.completedAt,
    this.cancellationReason,
    this.notes,
    this.createdAt,
  });

  factory RealEstateVisitModel.fromJson(Map<String, dynamic> json) {
    return RealEstateVisitModel(
      id: _idOf(json),
      propertyId: _refId(json['property']) ?? RealEstatePropertyRef.tryParse(json['property'])?.id,
      property: RealEstatePropertyRef.tryParse(json['property']),
      customerId: _refId(json['customer']) ?? RealEstateCustomerRef.tryParse(json['customer'])?.id,
      customer: RealEstateCustomerRef.tryParse(json['customer']),
      leadId: _refId(json['lead']) ?? RealEstateLeadRef.tryParse(json['lead'])?.id,
      lead: RealEstateLeadRef.tryParse(json['lead']),
      executiveId: _execId(json['executive']),
      executiveName: _execName(json['executive']),
      executiveMobile: _execMobile(json['executive']),
      requestId: _str(json['request']),
      status: _str(json['status']),
      scheduledAt: _date(json['scheduledAt']),
      checkInRadiusMeters: _int(json['checkInRadiusMeters']),
      checkIn: _map(json['checkIn']),
      startedAt: _date(json['startedAt']),
      completedAt: _date(json['completedAt']),
      cancellationReason: _str(json['cancellationReason']),
      notes: _str(json['notes']),
      createdAt: _date(json['createdAt']),
    );
  }
}
