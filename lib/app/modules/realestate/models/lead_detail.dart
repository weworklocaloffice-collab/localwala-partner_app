/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:partner/app/modules/realestate/models/follow_up.dart';
import 'package:partner/app/modules/realestate/models/hold.dart';
import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/app/modules/realestate/models/sale.dart';
import 'package:partner/app/modules/realestate/models/visit.dart';

/// A lead with its crossroads: visits, follow-ups, hold, sale and the
/// latest loan request status.
///
/// The backend joins all of it in `getLeadDetail`, so one call renders
/// the whole screen. Full loan models live with the executive loan
/// screens; here only the status travels (read-only).
class RealEstateLeadDetail {
  final RealEstateLeadModel lead;
  final List<RealEstateVisitModel> visits;
  final List<RealEstateFollowUpModel> followUps;
  final RealEstateHoldModel? hold;
  final RealEstateSaleModel? sale;
  final String? latestLoanStatus;

  const RealEstateLeadDetail({
    required this.lead,
    this.visits = const <RealEstateVisitModel>[],
    this.followUps = const <RealEstateFollowUpModel>[],
    this.hold,
    this.sale,
    this.latestLoanStatus,
  });

  factory RealEstateLeadDetail.fromJson(Map<String, dynamic> json) {
    List<RealEstateVisitModel> visits = const <RealEstateVisitModel>[];
    if (json['visits'] is List) {
      visits = (json['visits'] as List)
          .whereType<Map>()
          .map((Map m) => RealEstateVisitModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    List<RealEstateFollowUpModel> followUps = const <RealEstateFollowUpModel>[];
    if (json['followUps'] is List) {
      followUps = (json['followUps'] as List)
          .whereType<Map>()
          .map((Map m) => RealEstateFollowUpModel.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    String? loanStatus;
    if (json['loanRequests'] is List && (json['loanRequests'] as List).isNotEmpty) {
      final dynamic first = (json['loanRequests'] as List).first;
      if (first is Map) loanStatus = first['status']?.toString();
    }
    return RealEstateLeadDetail(
      lead: RealEstateLeadModel.fromJson(json),
      visits: visits,
      followUps: followUps,
      hold: json['hold'] is Map ? RealEstateHoldModel.fromJson(Map<String, dynamic>.from(json['hold'])) : null,
      sale: json['sale'] is Map ? RealEstateSaleModel.fromJson(Map<String, dynamic>.from(json['sale'])) : null,
      latestLoanStatus: loanStatus,
    );
  }
}
