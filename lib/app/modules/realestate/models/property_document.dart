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

DateTime? _date(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

/// A verification document on a vendor listing (BR-18, BR-21).
///
/// A vendor may set visibility to INTERNAL or CUSTOMER_VISIBLE only;
/// ACCEPTED documents cannot be removed. Wire shape only (plan §12).
class RealEstateDocumentModel {
  final String id;
  final String? propertyId;
  final String? category;
  final String? visibility;
  final String? title;
  final String? fileUrl;
  final String? fileName;
  final String? mimeType;
  final int? sizeBytes;
  final String? checksum;
  final String? notes;
  final String? status;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final String? rejectionReason;
  final String? uploadedBy;
  final DateTime? createdAt;

  const RealEstateDocumentModel({
    required this.id,
    this.propertyId,
    this.category,
    this.visibility,
    this.title,
    this.fileUrl,
    this.fileName,
    this.mimeType,
    this.sizeBytes,
    this.checksum,
    this.notes,
    this.status,
    this.verifiedAt,
    this.verifiedBy,
    this.rejectionReason,
    this.uploadedBy,
    this.createdAt,
  });

  factory RealEstateDocumentModel.fromJson(Map<String, dynamic> json) {
    return RealEstateDocumentModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      propertyId: _str(json['property']),
      category: _str(json['category']),
      visibility: _str(json['visibility']),
      title: _str(json['title']),
      fileUrl: _str(json['fileUrl']),
      fileName: _str(json['fileName']),
      mimeType: _str(json['mimeType']),
      sizeBytes: _intOrNull(json['sizeBytes']),
      checksum: _str(json['checksum']),
      notes: _str(json['notes']),
      status: _str(json['status']),
      verifiedAt: _date(json['verifiedAt']),
      verifiedBy: _str(json['verifiedBy']),
      rejectionReason: _str(json['rejectionReason']),
      uploadedBy: _str(json['uploadedBy']),
      createdAt: _date(json['createdAt']),
    );
  }
}
