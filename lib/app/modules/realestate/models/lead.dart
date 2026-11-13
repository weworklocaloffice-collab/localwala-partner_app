/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

String _idOf(Map<String, dynamic> json) => (json['_id'] ?? json['id'])?.toString() ?? '';

String? _str(dynamic v) => v == null ? null : (v is String ? v : v.toString());

/// An id that may arrive raw or inside a populated map. Maps yield null
/// here so callers fall through to the nested parse (`_str` would hand
/// back the map's `toString()` instead).
String? _refId(dynamic v) => v is Map ? null : _str(v);

int _int(dynamic v, [int dflt = 0]) {
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

/// The customer contact the lead/contact rows resolve to.
///
/// `customer` on lead, visit, hold and sale rows is populated with this
/// projection — never a second lookup per row.
class RealEstateCustomerRef {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? mobile;

  const RealEstateCustomerRef({
    required this.id,
    this.firstName,
    this.lastName,
    this.mobile,
  });

  /// Display name, falling back to the phone number, then the id.
  String get displayName {
    final String name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (name.isNotEmpty) return name;
    if (mobile != null && mobile!.isNotEmpty) return mobile!;
    return id;
  }

  factory RealEstateCustomerRef.fromJson(Map<String, dynamic> json) {
    return RealEstateCustomerRef(
      id: _idOf(json),
      firstName: _str(json['firstName']),
      lastName: _str(json['lastName']),
      mobile: _str(json['mobile']),
    );
  }

  static RealEstateCustomerRef? tryParse(dynamic v) =>
      v is Map<String, dynamic> ? RealEstateCustomerRef.fromJson(v) : (v is Map ? RealEstateCustomerRef.fromJson(Map<String, dynamic>.from(v)) : null);
}

/// The property projection the pipeline rows resolve to.
///
/// Lead, visit, hold and sale rows populate this — never a second lookup
/// per row. Money is deliberately NOT selected on these projections.
class RealEstatePropertyRef {
  final String id;
  final String? title;
  final String? propertyCode;
  final String? addressLine;
  final String? mapAddress;

  const RealEstatePropertyRef({
    required this.id,
    this.title,
    this.propertyCode,
    this.addressLine,
    this.mapAddress,
  });

  factory RealEstatePropertyRef.fromJson(Map<String, dynamic> json) {
    return RealEstatePropertyRef(
      id: _idOf(json),
      title: _str(json['title']),
      propertyCode: _str(json['propertyCode']),
      addressLine: _str(json['addressLine']),
      mapAddress: _str(json['mapAddress']),
    );
  }

  static RealEstatePropertyRef? tryParse(dynamic v) =>
      v is Map<String, dynamic> ? RealEstatePropertyRef.fromJson(v) : (v is Map ? RealEstatePropertyRef.fromJson(Map<String, dynamic>.from(v)) : null);
}

/// A lead on a vendor listing (BR-06, BR-07).
///
/// `customer` and `property` are populated; `vendor` / `executive` stay
/// raw ids — the controllers compare them with String() for ownership.
/// Wire shape only (plan §12).
class RealEstateLeadModel {
  final String id;
  final String? leadCode;
  final String? propertyId;
  final RealEstatePropertyRef? property;
  final String? customerId;
  final RealEstateCustomerRef? customer;
  final String? vendorId;
  final String? executiveId;
  final String? source;
  final String? status;
  final Map<String, dynamic>? interest;
  final String? lostReason;
  final String? reopenReason;
  final String? holdId;
  final String? saleId;
  final int visitCount;
  final int followUpCount;
  final DateTime? createdAt;
  final List<RealEstateLeadActivity> activities;

  const RealEstateLeadModel({
    required this.id,
    this.leadCode,
    this.propertyId,
    this.property,
    this.customerId,
    this.customer,
    this.vendorId,
    this.executiveId,
    this.source,
    this.status,
    this.interest,
    this.lostReason,
    this.reopenReason,
    this.holdId,
    this.saleId,
    this.visitCount = 0,
    this.followUpCount = 0,
    this.createdAt,
    this.activities = const <RealEstateLeadActivity>[],
  });

  factory RealEstateLeadModel.fromJson(Map<String, dynamic> json) {
    List<RealEstateLeadActivity> activities = const <RealEstateLeadActivity>[];
    if (json['activities'] is List) {
      activities = (json['activities'] as List)
          .whereType<Map>()
          .map((Map m) => RealEstateLeadActivity.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    return RealEstateLeadModel(
      id: _idOf(json),
      leadCode: _str(json['leadCode']),
      propertyId: _refId(json['property']) ?? RealEstatePropertyRef.tryParse(json['property'])?.id,
      property: RealEstatePropertyRef.tryParse(json['property']),
      customerId: _refId(json['customer']) ?? RealEstateCustomerRef.tryParse(json['customer'])?.id,
      customer: RealEstateCustomerRef.tryParse(json['customer']),
      vendorId: _str(json['vendor']),
      executiveId: _str(json['executive']),
      source: _str(json['source']),
      status: _str(json['status']),
      interest: _map(json['interest']),
      lostReason: _str(json['lostReason']),
      reopenReason: _str(json['reopenReason']),
      holdId: _str(json['hold']),
      saleId: _str(json['sale']),
      visitCount: _int(json['visitCount']),
      followUpCount: _int(json['followUpCount']),
      createdAt: _date(json['createdAt']),
      activities: activities,
    );
  }
}

/// One row of a lead's activity history (reassignments, status hops).
class RealEstateLeadActivity {
  final String id;
  final String? action;
  final String? fromStatus;
  final String? toStatus;
  final String? fromExecutiveId;
  final String? toExecutiveId;
  final String? actor;
  final String? actorType;
  final String? note;
  final DateTime? createdAt;

  const RealEstateLeadActivity({
    required this.id,
    this.action,
    this.fromStatus,
    this.toStatus,
    this.fromExecutiveId,
    this.toExecutiveId,
    this.actor,
    this.actorType,
    this.note,
    this.createdAt,
  });

  factory RealEstateLeadActivity.fromJson(Map<String, dynamic> json) {
    return RealEstateLeadActivity(
      id: _idOf(json),
      action: _str(json['action']),
      fromStatus: _str(json['fromStatus']),
      toStatus: _str(json['toStatus']),
      fromExecutiveId: _str(json['fromExecutive']),
      toExecutiveId: _str(json['toExecutive']),
      actor: _str(json['actor']),
      actorType: _str(json['actorType']),
      note: _str(json['note']),
      createdAt: _date(json['createdAt']),
    );
  }
}
