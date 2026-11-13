/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:partner/app/env.dart';

String _idOf(Map<String, dynamic> json) => (json['_id'] ?? json['id'])?.toString() ?? '';
String? _str(dynamic v) => v == null ? null : (v is String ? v : v.toString());

double? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
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

bool _bool(dynamic v, [bool dflt = false]) => v is bool ? v : dflt;

List<String> _strList(dynamic v) =>
    v is List ? v.map((dynamic e) => e.toString()).toList() : const <String>[];

List<Map<String, dynamic>> _mapList(dynamic v) => v is List
    ? v.whereType<Map>().map((Map m) => Map<String, dynamic>.from(m)).toList()
    : const <Map<String, dynamic>>[];

Map<String, dynamic>? _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

/// Formats a rupee amount with lakh/crore grouping (`1.5 Cr`, `50 Lakh`).
///
/// Lives next to the model, like the customer app's copy: every price
/// surface in the module formats the same way, and the wire already
/// arrives in rupees (money-edges gate), so no conversion happens here.
String formatIndianPrice(double v) {
  final double n = v;
  if (n >= 10000000) return '${(n / 10000000).toStringAsFixed(n % 10000000 == 0 ? 0 : 2)} Cr';
  if (n >= 100000) return '${(n / 100000).toStringAsFixed(n % 100000 == 0 ? 0 : 2)} Lakh';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
  return n.toStringAsFixed(0);
}

/// Resolves a media `url` to something renderable.
///
/// Absolute URLs pass through. Anything else is a storage key from
/// `v1/file/uploadImage`, which local deployments serve under
/// `/storage/` (see `app.js` static mount) — so it is prefixed with the
/// API base URL. Cloud keys need deployment-side public URLs, a platform
/// gap shared with every other upload surface, not this form.
String resolveMediaUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final String base = Environments.apiBaseURL.endsWith('/')
      ? Environments.apiBaseURL.substring(0, Environments.apiBaseURL.length - 1)
      : Environments.apiBaseURL;
  final String key = url.startsWith('/') ? url.substring(1) : url;
  return '$base/storage/$key';
}

/// A Real Estate listing as the partner surfaces return it.
///
/// Wire shape only — no behaviour, no vertical branching (plan §12).
/// Money arrives in rupees (money-edges gate); ids arrive as `_id`
/// (service reads) or `id` (paginated reads) — both parse.
class RealEstatePropertyModel {
  final String id;
  final String? propertyCode;
  final String? source;
  final String? vendorId;
  final String? categoryId;
  final Map<String, dynamic>? categorySnapshot;
  final String? transactionType;
  final double? price;
  final bool priceOnRequest;
  final String? pricePeriod;
  final String? addressLine;
  final String? mapAddress;
  final String? localityId;
  final String? cityId;
  final String? stateId;
  final String? pincode;
  final double? longitude;
  final double? latitude;
  final Map<String, dynamic>? specs;
  final List<String> amenities;
  final List<Map<String, dynamic>> media;
  final String? title;
  final String? description;
  final String? projectName;
  final String? builderName;
  final String? status;
  final String? availability;
  final String? entitlementId;
  final DateTime? submittedAt;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final DateTime? verifiedAt;
  final int views;
  final int enquiries;
  final int visits;
  final int leads;
  final String? statusReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RealEstatePropertyModel({
    required this.id,
    this.propertyCode,
    this.source,
    this.vendorId,
    this.categoryId,
    this.categorySnapshot,
    this.transactionType,
    this.price,
    this.priceOnRequest = false,
    this.pricePeriod,
    this.addressLine,
    this.mapAddress,
    this.localityId,
    this.cityId,
    this.stateId,
    this.pincode,
    this.longitude,
    this.latitude,
    this.specs,
    this.amenities = const <String>[],
    this.media = const <Map<String, dynamic>>[],
    this.title,
    this.description,
    this.projectName,
    this.builderName,
    this.status,
    this.availability,
    this.entitlementId,
    this.submittedAt,
    this.publishedAt,
    this.expiresAt,
    this.verifiedAt,
    this.views = 0,
    this.enquiries = 0,
    this.visits = 0,
    this.leads = 0,
    this.statusReason,
    this.createdAt,
    this.updatedAt,
  });

  factory RealEstatePropertyModel.fromJson(Map<String, dynamic> json) {
    double? lng;
    double? lat;
    final dynamic location = json['location'];
    if (location is Map && location['coordinates'] is List) {
      final List<dynamic> c = location['coordinates'] as List<dynamic>;
      if (c.length >= 2) {
        lng = _num(c[0]);
        lat = _num(c[1]);
      }
    }
    return RealEstatePropertyModel(
      id: _idOf(json),
      propertyCode: _str(json['propertyCode']),
      source: _str(json['source']),
      vendorId: _str(json['vendor']),
      categoryId: _str(json['category']),
      categorySnapshot: _map(json['categorySnapshot']),
      transactionType: _str(json['transactionType']),
      price: _num(json['price']),
      priceOnRequest: _bool(json['priceOnRequest']),
      pricePeriod: _str(json['pricePeriod']),
      addressLine: _str(json['addressLine']),
      mapAddress: _str(json['mapAddress']),
      localityId: _str(json['locality']),
      cityId: _str(json['city']),
      stateId: _str(json['state']),
      pincode: _str(json['pincode']),
      longitude: lng,
      latitude: lat,
      specs: _map(json['specs']),
      amenities: _strList(json['amenities']),
      media: _mapList(json['media']),
      title: _str(json['title']),
      description: _str(json['description']),
      projectName: _str(json['projectName']),
      builderName: _str(json['builderName']),
      status: _str(json['status']),
      availability: _str(json['availability']),
      entitlementId: _str(json['entitlement']),
      submittedAt: _date(json['submittedAt']),
      publishedAt: _date(json['publishedAt']),
      expiresAt: _date(json['expiresAt']),
      verifiedAt: _date(json['verifiedAt']),
      views: _int(json['views']),
      enquiries: _int(json['enquiries']),
      visits: _int(json['visits']),
      leads: _int(json['leads']),
      statusReason: _str(json['statusReason']),
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }
}
