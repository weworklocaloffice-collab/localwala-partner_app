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

/// A scheduled follow-up on a lead. Wire shape only (plan §12).
class RealEstateFollowUpModel {
  final String id;
  final String? leadId;
  final String? executiveId;
  final String? status;
  final DateTime? nextFollowUpAt;
  final String? mode;
  final String? notes;
  final DateTime? completedAt;
  final String? completedBy;
  final DateTime? createdAt;

  const RealEstateFollowUpModel({
    required this.id,
    this.leadId,
    this.executiveId,
    this.status,
    this.nextFollowUpAt,
    this.mode,
    this.notes,
    this.completedAt,
    this.completedBy,
    this.createdAt,
  });

  factory RealEstateFollowUpModel.fromJson(Map<String, dynamic> json) {
    return RealEstateFollowUpModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      leadId: _str(json['lead']),
      executiveId: _str(json['executive']),
      status: _str(json['status']),
      nextFollowUpAt: _date(json['nextFollowUpAt']),
      mode: _str(json['mode']),
      notes: _str(json['notes']),
      completedAt: _date(json['completedAt']),
      completedBy: _str(json['completedBy']),
      createdAt: _date(json['createdAt']),
    );
  }
}
