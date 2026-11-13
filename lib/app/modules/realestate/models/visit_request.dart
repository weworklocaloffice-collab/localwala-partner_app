/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

String _idOf(Map<String, dynamic> json) => (json['_id'] ?? json['id'])?.toString() ?? '';
String? _str(dynamic v) => v == null ? null : (v is String ? v : v.toString());

/// An id that may arrive raw or inside a populated map (see lead.dart).
String? _refId(dynamic v) => v is Map ? null : _str(v);

double? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

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

/// The property projection a visit request resolves to.
///
/// Includes the price (rupees — money-edges gate) for the schedule rows.
class RealEstateVisitProperty {
  final String id;
  final String? title;
  final double? price;
  final String? pricePeriod;
  final String? transactionType;
  final String? availability;

  const RealEstateVisitProperty({
    required this.id,
    this.title,
    this.price,
    this.pricePeriod,
    this.transactionType,
    this.availability,
  });

  factory RealEstateVisitProperty.fromJson(Map<String, dynamic> json) {
    return RealEstateVisitProperty(
      id: _idOf(json),
      title: _str(json['title']),
      price: _num(json['price']),
      pricePeriod: _str(json['pricePeriod']),
      transactionType: _str(json['transactionType']),
      availability: _str(json['availability']),
    );
  }

  static RealEstateVisitProperty? tryParse(dynamic v) => v is Map
      ? RealEstateVisitProperty.fromJson(Map<String, dynamic>.from(v))
      : null;
}

/// The visit projection a visit request resolves to.
class RealEstateVisitRef {
  final String id;
  final String? status;
  final DateTime? scheduledAt;

  const RealEstateVisitRef({required this.id, this.status, this.scheduledAt});

  factory RealEstateVisitRef.fromJson(Map<String, dynamic> json) {
    return RealEstateVisitRef(
      id: _idOf(json),
      status: _str(json['status']),
      scheduledAt: _date(json['scheduledAt']),
    );
  }

  static RealEstateVisitRef? tryParse(dynamic v) => v is Map
      ? RealEstateVisitRef.fromJson(Map<String, dynamic>.from(v))
      : null;
}

/// The lead projection a visit request resolves to.
class RealEstateLeadRef {
  final String id;
  final String? leadCode;
  final String? status;

  const RealEstateLeadRef({required this.id, this.leadCode, this.status});

  factory RealEstateLeadRef.fromJson(Map<String, dynamic> json) {
    return RealEstateLeadRef(id: _idOf(json), leadCode: _str(json['leadCode']), status: _str(json['status']));
  }

  static RealEstateLeadRef? tryParse(dynamic v) => v is Map
      ? RealEstateLeadRef.fromJson(Map<String, dynamic>.from(v))
      : null;
}

/// A customer's visit request through every visit state, PENDING_ASSIGNMENT
/// onward — one list serves both upcoming and past. Wire shape only.
class RealEstateVisitRequestModel {
  final String id;
  final String? propertyId;
  final RealEstateVisitProperty? property;
  final String? customerId;
  final String? leadId;
  final RealEstateLeadRef? lead;
  final String? executiveId;
  final String? status;
  final DateTime? preferredDate;
  final String? preferredTimeSlot;
  final String? visitId;
  final RealEstateVisitRef? visit;
  final int checkInRadiusMeters;
  final String? cancellationReason;
  final DateTime? createdAt;

  const RealEstateVisitRequestModel({
    required this.id,
    this.propertyId,
    this.property,
    this.customerId,
    this.leadId,
    this.lead,
    this.executiveId,
    this.status,
    this.preferredDate,
    this.preferredTimeSlot,
    this.visitId,
    this.visit,
    this.checkInRadiusMeters = 200,
    this.cancellationReason,
    this.createdAt,
  });

  factory RealEstateVisitRequestModel.fromJson(Map<String, dynamic> json) {
    return RealEstateVisitRequestModel(
      id: _idOf(json),
      propertyId: _refId(json['property']) ?? RealEstateVisitProperty.tryParse(json['property'])?.id,
      property: RealEstateVisitProperty.tryParse(json['property']),
      customerId: _str(json['customer']),
      leadId: _refId(json['lead']) ?? RealEstateLeadRef.tryParse(json['lead'])?.id,
      lead: RealEstateLeadRef.tryParse(json['lead']),
      executiveId: _str(json['executive']),
      status: _str(json['status']),
      preferredDate: _date(json['preferredDate']),
      preferredTimeSlot: _str(json['preferredTimeSlot']),
      visitId: _refId(json['visit']) ?? RealEstateVisitRef.tryParse(json['visit'])?.id,
      visit: RealEstateVisitRef.tryParse(json['visit']),
      checkInRadiusMeters: _int(json['checkInRadiusMeters']),
      cancellationReason: _str(json['cancellationReason']),
      createdAt: _date(json['createdAt']),
    );
  }
}
