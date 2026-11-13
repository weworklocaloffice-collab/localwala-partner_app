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

bool _bool(dynamic v, [bool dflt = false]) => v is bool ? v : dflt;

List<dynamic> _list(dynamic v) => v is List ? v : const <dynamic>[];

Map<String, dynamic>? _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

/// A listing package in the purchase catalogue (BR-02).
///
/// `price` arrives in rupees (money-edges gate). `listingCount` null
/// means unlimited. Wire shape only (plan §12).
class RealEstatePackageModel {
  final String id;
  final String? code;
  final String? name;
  final String? description;
  final double? price;
  final int? listingCount;
  final int? durationDays;
  final List<dynamic> features;
  final Map<String, dynamic>? limits;
  final int sortOrder;
  final bool status;
  final bool recommended;

  const RealEstatePackageModel({
    required this.id,
    this.code,
    this.name,
    this.description,
    this.price,
    this.listingCount,
    this.durationDays,
    this.features = const <dynamic>[],
    this.limits,
    this.sortOrder = 0,
    this.status = true,
    this.recommended = false,
  });

  factory RealEstatePackageModel.fromJson(Map<String, dynamic> json) {
    return RealEstatePackageModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      code: _str(json['code']),
      name: _str(json['name']),
      description: _str(json['description']),
      price: _num(json['price']),
      listingCount: _intOrNull(json['listingCount']),
      durationDays: _intOrNull(json['durationDays']),
      features: _list(json['features']),
      limits: _map(json['limits']),
      sortOrder: _int(json['sortOrder']),
      status: _bool(json['status'], true),
      recommended: _bool(json['recommended']),
    );
  }
}
