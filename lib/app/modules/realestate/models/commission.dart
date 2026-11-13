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

DateTime? _date(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

Map<String, dynamic>? _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

/// A commission entry (BR-15, BR-17).
///
/// The vendor sees sales commission only — never mixed with package
/// spend, and never another party's. Amounts arrive in rupees
/// (money-edges gate). Wire shape only (plan §12).
class RealEstateCommissionModel {
  final String id;
  final String? commissionNo;
  final String? saleId;
  final String? holdId;
  final String? loanApplicationId;
  final String? listingOrderId;
  final String? ruleId;
  final Map<String, dynamic>? ruleSnapshot;
  final String? beneficiaryType;
  final String? beneficiaryId;
  final double? baseAmount;
  final double? rate;
  final double? amount;
  final String? status;
  final String? settlementId;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  const RealEstateCommissionModel({
    required this.id,
    this.commissionNo,
    this.saleId,
    this.holdId,
    this.loanApplicationId,
    this.listingOrderId,
    this.ruleId,
    this.ruleSnapshot,
    this.beneficiaryType,
    this.beneficiaryId,
    this.baseAmount,
    this.rate,
    this.amount,
    this.status,
    this.settlementId,
    this.resolvedAt,
    this.createdAt,
  });

  factory RealEstateCommissionModel.fromJson(Map<String, dynamic> json) {
    return RealEstateCommissionModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      commissionNo: _str(json['commissionNo']),
      saleId: _str(json['sale']),
      holdId: _str(json['hold']),
      loanApplicationId: _str(json['loanApplication']),
      listingOrderId: _str(json['listingOrder']),
      ruleId: _str(json['rule']),
      ruleSnapshot: _map(json['ruleSnapshot']),
      beneficiaryType: _str(json['beneficiaryType']),
      beneficiaryId: _str(json['beneficiary']),
      baseAmount: _num(json['baseAmount']),
      rate: _num(json['rate']),
      amount: _num(json['amount']),
      status: _str(json['status']),
      settlementId: _str(json['settlement']),
      resolvedAt: _date(json['resolvedAt']),
      createdAt: _date(json['createdAt']),
    );
  }
}
