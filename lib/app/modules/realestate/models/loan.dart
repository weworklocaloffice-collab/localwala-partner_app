/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Ac 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:partner/app/modules/realestate/models/lead.dart';

String _idOf(Map<String, dynamic> json) => (json['_id'] ?? json['id'])?.toString() ?? '';

String? _str(dynamic v) => v == null ? null : (v is String ? v : v.toString());

String? _refId(dynamic v) => v is Map ? null : _str(v);

double? _num(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _int(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

List<Map<String, dynamic>> _mapList(dynamic v) => v is List
    ? v.whereType<Map>().map((Map m) => Map<String, dynamic>.from(m)).toList()
    : const <Map<String, dynamic>>[];

class RealEstateBankRef {
  final String id;
  final String? name;
  final String? code;

  const RealEstateBankRef({required this.id, this.name, this.code});

  String get displayName => name ?? code ?? id;

  factory RealEstateBankRef.fromJson(Map<String, dynamic> json) {
    return RealEstateBankRef(
      id: _idOf(json),
      name: _str(json['name']),
      code: _str(json['code']),
    );
  }

  static RealEstateBankRef? tryParse(dynamic v) => v is Map
      ? RealEstateBankRef.fromJson(Map<String, dynamic>.from(v))
      : null;
}

class RealEstateBankOfferModel {
  final String id;
  final RealEstateBankRef? bank;
  final double? loanAmount;
  final int? tenureMonths;
  final double? interestRate;
  final double? processingFee;
  final String? otherTerms;
  final String? status;
  final DateTime? createdAt;

  const RealEstateBankOfferModel({
    required this.id,
    this.bank,
    this.loanAmount,
    this.tenureMonths,
    this.interestRate,
    this.processingFee,
    this.otherTerms,
    this.status,
    this.createdAt,
  });

  factory RealEstateBankOfferModel.fromJson(Map<String, dynamic> json) {
    return RealEstateBankOfferModel(
      id: _idOf(json),
      bank: RealEstateBankRef.tryParse(json['bank']),
      loanAmount: _num(json['loanAmount']),
      tenureMonths: _int(json['tenureMonths']),
      interestRate: _num(json['interestRate']),
      processingFee: _num(json['processingFee']),
      otherTerms: _str(json['otherTerms']),
      status: _str(json['status']),
      createdAt: _date(json['createdAt']),
    );
  }
}

class RealEstateLoanApplicationModel {
  final String id;
  final RealEstateBankRef? bank;
  final double? requestedAmount;
  final double? sanctionedAmount;
  final double? disbursedAmount;
  final int? tenureMonths;
  final double? interestRate;
  final String? status;
  final DateTime? sanctionedAt;
  final DateTime? disbursedAt;
  final DateTime? rejectedAt;
  final String? rejectionReason;
  final DateTime? createdAt;
  final List<RealEstateBankOfferModel> offers;

  const RealEstateLoanApplicationModel({
    required this.id,
    this.bank,
    this.requestedAmount,
    this.sanctionedAmount,
    this.disbursedAmount,
    this.tenureMonths,
    this.interestRate,
    this.status,
    this.sanctionedAt,
    this.disbursedAt,
    this.rejectedAt,
    this.rejectionReason,
    this.createdAt,
    this.offers = const <RealEstateBankOfferModel>[],
  });

  factory RealEstateLoanApplicationModel.fromJson(Map<String, dynamic> json) {
    final String? bankId = _refId(json['bank']);
    return RealEstateLoanApplicationModel(
      id: _idOf(json),
      bank: RealEstateBankRef.tryParse(json['bank']) ??
          (bankId != null ? RealEstateBankRef(id: bankId) : null),
      requestedAmount: _num(json['requestedAmount']),
      sanctionedAmount: _num(json['sanctionedAmount']),
      disbursedAmount: _num(json['disbursedAmount']),
      tenureMonths: _int(json['tenureMonths']),
      interestRate: _num(json['interestRate']),
      status: _str(json['status']),
      sanctionedAt: _date(json['sanctionedAt']),
      disbursedAt: _date(json['disbursedAt']),
      rejectedAt: _date(json['rejectedAt']),
      rejectionReason: _str(json['rejectionReason']),
      createdAt: _date(json['createdAt']),
      offers: _mapList(json['offers'])
          .map(RealEstateBankOfferModel.fromJson)
          .toList(),
    );
  }
}

class RealEstateLoanModel {
  final String id;
  final RealEstateCustomerRef? customer;
  final RealEstatePropertyRef? property;
  final double? requestedAmount;
  final int? tenureMonths;
  final String? employment;
  final double? monthlyIncome;
  final String? status;
  final DateTime? createdAt;
  final List<RealEstateLoanApplicationModel> applications;

  const RealEstateLoanModel({
    required this.id,
    this.customer,
    this.property,
    this.requestedAmount,
    this.tenureMonths,
    this.employment,
    this.monthlyIncome,
    this.status,
    this.createdAt,
    this.applications = const <RealEstateLoanApplicationModel>[],
  });

  factory RealEstateLoanModel.fromJson(Map<String, dynamic> json) {
    return RealEstateLoanModel(
      id: _idOf(json),
      customer: RealEstateCustomerRef.tryParse(json['customer']),
      property: RealEstatePropertyRef.tryParse(json['property']),
      requestedAmount: _num(json['requestedAmount']),
      tenureMonths: _int(json['tenureMonths']),
      employment: _str(json['employment']),
      monthlyIncome: _num(json['monthlyIncome']),
      status: _str(json['status']),
      createdAt: _date(json['createdAt']),
      applications: _mapList(json['applications'])
          .map(RealEstateLoanApplicationModel.fromJson)
          .toList(),
    );
  }
}
