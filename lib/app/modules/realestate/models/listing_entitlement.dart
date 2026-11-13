/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

String? _str(dynamic v) => v == null ? null : (v is String ? v : v.toString());

int? _intOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

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

/// A listing entitlement: what a paid order bought (BR-05).
///
/// `totalCount` null means unlimited. Wire shape only (plan §12).
class RealEstateEntitlementModel {
  final String id;
  final String? vendorId;
  final String? orderId;
  final String? packageId;
  final Map<String, dynamic>? packageSnapshot;
  final int? totalCount;
  final int consumedCount;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final String? status;
  final DateTime? createdAt;

  const RealEstateEntitlementModel({
    required this.id,
    this.vendorId,
    this.orderId,
    this.packageId,
    this.packageSnapshot,
    this.totalCount,
    this.consumedCount = 0,
    this.effectiveFrom,
    this.effectiveTo,
    this.status,
    this.createdAt,
  });

  factory RealEstateEntitlementModel.fromJson(Map<String, dynamic> json) {
    return RealEstateEntitlementModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      vendorId: _str(json['vendor']),
      orderId: _str(json['order']),
      packageId: _str(json['package']),
      packageSnapshot: _map(json['packageSnapshot']),
      totalCount: _intOrNull(json['totalCount']),
      consumedCount: _int(json['consumedCount']),
      effectiveFrom: _date(json['effectiveFrom']),
      effectiveTo: _date(json['effectiveTo']),
      status: _str(json['status']),
      createdAt: _date(json['createdAt']),
    );
  }
}
