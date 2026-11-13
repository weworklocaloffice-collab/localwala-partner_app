/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

String? _str(dynamic v) => v == null ? null : (v is String ? v : v.toString());

DateTime? _date(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

/// Structured customer interest recorded by the executive (BR-09).
///
/// A closed level and a closed reason — free text only as the OTHER
/// escape hatch (`reasonText`). Wire shape only (plan §12).
class RealEstateInterestModel {
  final String id;
  final String? visitId;
  final String? leadId;
  final String? level;
  final String? reason;
  final String? reasonText;
  final String? recordedBy;
  final DateTime? recordedAt;
  final DateTime? createdAt;

  const RealEstateInterestModel({
    required this.id,
    this.visitId,
    this.leadId,
    this.level,
    this.reason,
    this.reasonText,
    this.recordedBy,
    this.recordedAt,
    this.createdAt,
  });

  factory RealEstateInterestModel.fromJson(Map<String, dynamic> json) {
    return RealEstateInterestModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      visitId: _str(json['visit']),
      leadId: _str(json['lead']),
      level: _str(json['level']),
      reason: _str(json['reason']),
      reasonText: _str(json['reasonText']),
      recordedBy: _str(json['recordedBy']),
      recordedAt: _date(json['recordedAt']),
      createdAt: _date(json['createdAt']),
    );
  }
}
