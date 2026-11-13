/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
 * All Rights Reserved.
 */

String _idOf(Map<String, dynamic> json) => (json['_id'] ?? json['id'])?.toString() ?? '';

String? _str(dynamic v) => v == null ? null : (v is String ? v : v.toString());

double? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

class RealEstateSettlementModel {
  final String id;
  final String? settlementNo;
  final String? partyType;
  final DateTime? periodFrom;
  final DateTime? periodTo;
  final double? gross;
  final double? tds;
  final double? net;
  final String? status;
  final DateTime? paidAt;
  final String? payoutReference;
  final DateTime? createdAt;

  const RealEstateSettlementModel({
    required this.id,
    this.settlementNo,
    this.partyType,
    this.periodFrom,
    this.periodTo,
    this.gross,
    this.tds,
    this.net,
    this.status,
    this.paidAt,
    this.payoutReference,
    this.createdAt,
  });

  factory RealEstateSettlementModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> totals =
        json['totals'] is Map ? Map<String, dynamic>.from(json['totals'] as Map) : <String, dynamic>{};
    return RealEstateSettlementModel(
      id: _idOf(json),
      settlementNo: _str(json['settlementNo']),
      partyType: _str(json['partyType']),
      periodFrom: _date(json['periodFrom']),
      periodTo: _date(json['periodTo']),
      gross: _num(totals['gross']),
      tds: _num(totals['tds']),
      net: _num(totals['net']),
      status: _str(json['status']),
      paidAt: _date(json['paidAt']),
      payoutReference: _str(json['payoutReference']),
      createdAt: _date(json['createdAt']),
    );
  }
}
