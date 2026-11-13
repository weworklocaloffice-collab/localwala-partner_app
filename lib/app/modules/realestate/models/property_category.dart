/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

String? _str(dynamic v) => v == null ? null : (v is String ? v : v.toString());

int _int(dynamic v, [int dflt = 0]) {
  if (v == null) return dflt;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? dflt;
}

bool _bool(dynamic v, [bool dflt = true]) => v is bool ? v : dflt;

List<String> _strList(dynamic v) =>
    v is List ? v.map((dynamic e) => e.toString()).toList() : const <String>[];

Map<String, dynamic>? _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

/// A property category: the vocabulary the listing form renders.
///
/// `specSchema` is the category-driven field descriptors the form builds
/// itself from; `amenityOptions` is the closed amenity vocabulary.
/// Wire shape only (plan §12).
class RealEstateCategoryModel {
  final String id;
  final String? key;
  final String? name;
  final String? group;
  final String? description;
  final String? icon;
  final List<String> transactionTypes;
  final Map<String, dynamic>? specSchema;
  final List<String> amenityOptions;
  final List<String> filterableKeys;
  final int sortOrder;
  final bool requiresReview;
  final bool status;

  const RealEstateCategoryModel({
    required this.id,
    this.key,
    this.name,
    this.group,
    this.description,
    this.icon,
    this.transactionTypes = const <String>[],
    this.specSchema,
    this.amenityOptions = const <String>[],
    this.filterableKeys = const <String>[],
    this.sortOrder = 0,
    this.requiresReview = true,
    this.status = true,
  });

  factory RealEstateCategoryModel.fromJson(Map<String, dynamic> json) {
    return RealEstateCategoryModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      key: _str(json['key']),
      name: _str(json['name']),
      group: _str(json['group']),
      description: _str(json['description']),
      icon: _str(json['icon']),
      transactionTypes: _strList(json['transactionTypes']),
      specSchema: _map(json['specSchema']),
      amenityOptions: _strList(json['amenityOptions']),
      filterableKeys: _strList(json['filterableKeys']),
      sortOrder: _int(json['sortOrder']),
      requiresReview: _bool(json['requiresReview']),
      status: _bool(json['status']),
    );
  }
}
