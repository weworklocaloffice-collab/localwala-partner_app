/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/config/realestate_endpoints.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:partner/app/modules/realestate/models/commission.dart';
import 'package:partner/app/modules/realestate/models/follow_up.dart';
import 'package:partner/app/modules/realestate/models/hold.dart';
import 'package:partner/app/modules/realestate/models/interest.dart';
import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/app/modules/realestate/models/lead_detail.dart';
import 'package:partner/app/modules/realestate/models/loan.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/models/sale.dart';
import 'package:partner/app/modules/realestate/models/settlement.dart';
import 'package:partner/app/modules/realestate/models/visit.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

/// Executive surface of the Real Estate module (`/v1/realestate/executive`).
///
/// Same transport contract as [RealEstateVendorRepository]: parsed models
/// out, [RealEstateApiException] on failure, query parameters in the URL.
/// `RealEstatePage` and the exception live in the vendor repository file —
/// the two repositories are the module's only shared surface besides
/// `models/` (plan §11.7), so shared types stay inside it.
class RealEstateExecutiveRepository {
  RealEstateExecutiveRepository({AuthRepository? authRepository})
      : _auth = authRepository ?? AuthRepository();

  final AuthRepository _auth;

  String _path(String template, [Map<String, String> values = const <String, String>{}]) {
    return RealEstateEndpoints.resolve(template, values);
  }

  String _qs(Map<String, String?> params) {
    final String q = params.entries
        .where((MapEntry<String, String?> e) => e.value != null && e.value!.isNotEmpty)
        .map((MapEntry<String, String?> e) => '${e.key}=${Uri.encodeComponent(e.value!)}')
        .join('&');
    return q.isEmpty ? '' : '?$q';
  }

  Never _fail(DioApiResponse response, String action) {
    final Map<String, dynamic> body = decodeBody(response);
    final dynamic message = body['message'] ?? body['error'];
    throw RealEstateApiException(
      message?.toString() ?? '$action failed',
      response.statusCode,
    );
  }

  Future<Map<String, dynamic>> _getMap(String url) async {
    final DioApiResponse response = await ApiRequestService.makeRequest(
      url,
      method: 'GET',
      token: await _auth.authToken(),
    );
    if (response.errorType != NetErrorType.none) _fail(response, 'GET $url');
    return decodeBody(response);
  }

  Future<Map<String, dynamic>> _mutate(
    String url, {
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final DioApiResponse response = await ApiRequestService.makeRequest(
      url,
      method: method,
      token: await _auth.authToken(),
      body: body,
    );
    if (response.errorType != NetErrorType.none) _fail(response, '$method $url');
    return decodeBody(response);
  }

  RealEstatePage<T> _page<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) parse, {
    int page = 1,
    int limit = 20,
  }) {
    final List<dynamic> raw = body['results'] is List ? body['results'] as List<dynamic> : const <dynamic>[];
    final List<T> items = raw.whereType<Map>().map((Map m) => parse(Map<String, dynamic>.from(m))).toList();
    final dynamic total = body['total'] ?? body['totalResults'];
    return RealEstatePage<T>(
      items: items,
      page: body['page'] is num ? (body['page'] as num).toInt() : page,
      limit: body['limit'] is num ? (body['limit'] as num).toInt() : limit,
      total: total is num ? total.toInt() : items.length,
    );
  }

  T? _single<T>(Map<String, dynamic> body, T Function(Map<String, dynamic>) parse) {
    final dynamic data = body['data'];
    if (data is Map) return parse(Map<String, dynamic>.from(data));
    return null;
  }

  //// Self and dashboard ////

  Future<Map<String, dynamic>> me() async {
    return _single(await _getMap(_path(RealEstateEndpoints.executiveMe)), (Map<String, dynamic> m) => m) ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> dashboard({int page = 1, int limit = 20}) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.executiveDashboard)}${_qs(<String, String?>{
            'page': page.toString(),
            'limit': limit.toString(),
          })}',
    );
    final dynamic data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  /// Records the executive's position. It does NOT feed the check-in
  /// geofence — check-in always measures the coordinates sent with it.
  Future<Map<String, dynamic>> updateLocation({required double lng, required double lat}) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.executiveLocation),
      method: 'POST',
      body: <String, dynamic>{
        'coordinates': <double>[lng, lat],
      },
    );
    final dynamic data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  //// Visits (BR-08: named transitions, never a generic setter) ////

  Future<RealEstatePage<RealEstateVisitModel>> visits({
    String? status,
    String? leadId,
    String? propertyId,
    DateTime? from,
    DateTime? to,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.executiveVisits)}${_qs(<String, String?>{
            'status': status,
            'lead': leadId,
            'property': propertyId,
            'from': from?.toIso8601String(),
            'to': to?.toIso8601String(),
            'page': page.toString(),
            'limit': limit.toString(),
          })}',
    );
    return _page(body, RealEstateVisitModel.fromJson, page: page, limit: limit);
  }

  Future<RealEstateVisitModel?> visit(String id) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.executiveVisit, <String, String>{'id': id}),
    );
    return _single(body, RealEstateVisitModel.fromJson);
  }

  Future<RealEstateVisitModel?> acceptVisit(String id) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.executiveVisitAccept, <String, String>{'id': id}),
      method: 'POST',
      body: <String, dynamic>{},
    );
    return _single(body, RealEstateVisitModel.fromJson);
  }

  /// Geofenced check-in. A 403 means the executive is outside the visit's
  /// radius — the screen shows the distance, not a generic error.
  Future<RealEstateVisitModel?> checkIn(String id, {required double lng, required double lat}) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.executiveVisitCheckIn, <String, String>{'id': id}),
      method: 'POST',
      body: <String, dynamic>{
        'coordinates': <double>[lng, lat],
      },
    );
    return _single(body, RealEstateVisitModel.fromJson);
  }

  Future<RealEstateVisitModel?> completeVisit(String id, {String? notes}) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.executiveVisitComplete, <String, String>{'id': id}),
      method: 'POST',
      body: <String, dynamic>{
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return _single(body, RealEstateVisitModel.fromJson);
  }

  Future<RealEstateVisitModel?> cancelVisit(String id, {required String reason}) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.executiveVisitCancel, <String, String>{'id': id}),
      method: 'POST',
      body: <String, dynamic>{'reason': reason},
    );
    return _single(body, RealEstateVisitModel.fromJson);
  }

  Future<RealEstateVisitModel?> addVisitNotes(String id, String notes) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.executiveVisitNotes, <String, String>{'id': id}),
      method: 'POST',
      body: <String, dynamic>{'notes': notes},
    );
    return _single(body, RealEstateVisitModel.fromJson);
  }

  //// Interest (BR-09) and follow-ups ////

  Future<RealEstateInterestModel?> recordInterest(
    String visitId, {
    required String level,
    required String reason,
    String? reasonText,
  }) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.executiveVisitInterest, <String, String>{'id': visitId}),
      method: 'POST',
      body: <String, dynamic>{
        'level': level,
        'reason': reason,
        if (reasonText != null && reasonText.isNotEmpty) 'reasonText': reasonText,
      },
    );
    return _single(body, RealEstateInterestModel.fromJson);
  }

  Future<RealEstateFollowUpModel?> createFollowUp(
    String leadId, {
    required DateTime nextFollowUpAt,
    required String mode,
    String? notes,
  }) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.executiveLeadFollowUps, <String, String>{'leadId': leadId}),
      method: 'POST',
      body: <String, dynamic>{
        'nextFollowUpAt': nextFollowUpAt.toIso8601String(),
        'mode': mode,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return _single(body, RealEstateFollowUpModel.fromJson);
  }

  Future<RealEstateFollowUpModel?> completeFollowUp(String id) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.executiveFollowUpComplete, <String, String>{'id': id}),
      method: 'POST',
    );
    return _single(body, RealEstateFollowUpModel.fromJson);
  }

  //// Follow-ups (read-only list; writes stay on the transition routes) ////

  Future<RealEstatePage<RealEstateFollowUpModel>> followUps({int page = 1, int limit = 20}) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.executiveFollowUps)}${_qs(<String, String?>{
            'page': page.toString(),
            'limit': limit.toString(),
          })}',
    );
    return _page(body, RealEstateFollowUpModel.fromJson, page: page, limit: limit);
  }

  //// Money + queue reads (plan §11.4, all token-scoped, read-only) ////

  Future<RealEstatePage<RealEstateCommissionModel>> commissions({int page = 1, int limit = 20}) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.executiveCommissions)}${_qs(<String, String?>{
            'page': page.toString(),
            'limit': limit.toString(),
          })}',
    );
    return _page(body, RealEstateCommissionModel.fromJson, page: page, limit: limit);
  }

  Future<RealEstatePage<RealEstateHoldModel>> holds({int page = 1, int limit = 20}) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.executiveHolds)}${_qs(<String, String?>{
            'page': page.toString(),
            'limit': limit.toString(),
          })}',
    );
    return _page(body, RealEstateHoldModel.fromJson, page: page, limit: limit);
  }

  Future<RealEstateHoldModel?> hold(String id) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.executiveHold, <String, String>{'id': id}),
    );
    return _single(body, RealEstateHoldModel.fromJson);
  }

  Future<RealEstatePage<RealEstateLoanModel>> loans({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.executiveLoans)}${_qs(<String, String?>{
            'status': status,
            'page': page.toString(),
            'limit': limit.toString(),
          })}',
    );
    return _page(body, RealEstateLoanModel.fromJson, page: page, limit: limit);
  }

  Future<RealEstateLoanModel?> loan(String id) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.executiveLoan, <String, String>{'id': id}),
    );
    return _single(body, RealEstateLoanModel.fromJson);
  }

  Future<RealEstatePage<RealEstateSaleModel>> sales({int page = 1, int limit = 20}) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.executiveSales)}${_qs(<String, String?>{
            'page': page.toString(),
            'limit': limit.toString(),
          })}',
    );
    return _page(body, RealEstateSaleModel.fromJson, page: page, limit: limit);
  }

  Future<RealEstateSaleModel?> sale(String id) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.executiveSale, <String, String>{'id': id}),
    );
    return _single(body, RealEstateSaleModel.fromJson);
  }

  Future<RealEstatePage<RealEstateSettlementModel>> settlements({int page = 1, int limit = 20}) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.executiveSettlements)}${_qs(<String, String?>{
            'page': page.toString(),
            'limit': limit.toString(),
          })}',
    );
    return _page(body, RealEstateSettlementModel.fromJson, page: page, limit: limit);
  }

  Future<List<Map<String, dynamic>>> notifications({int page = 1, int limit = 20}) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.executiveNotifications)}${_qs(<String, String?>{
            'page': page.toString(),
            'limit': limit.toString(),
          })}',
    );
    final List<dynamic> raw = body['results'] is List ? body['results'] as List<dynamic> : const <dynamic>[];
    return raw.whereType<Map>().map((Map m) => Map<String, dynamic>.from(m)).toList();
  }

  Future<void> markNotificationRead(String id) async {
    await _mutate(
      _path(RealEstateEndpoints.executiveNotificationRead, <String, String>{'id': id}),
      method: 'POST',
    );
  }

  //// Leads and read-only property ////

  Future<RealEstatePage<RealEstateLeadModel>> leads({int page = 1, int limit = 20}) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.executiveLeads)}${_qs(<String, String?>{
            'page': page.toString(),
            'limit': limit.toString(),
          })}',
    );
    return _page(body, RealEstateLeadModel.fromJson, page: page, limit: limit);
  }

  Future<RealEstateLeadDetail?> lead(String leadId) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.executiveLead, <String, String>{'leadId': leadId}),
    );
    return _single(body, RealEstateLeadDetail.fromJson);
  }

  /// Read-only property detail for a visit — address and specs, never
  /// the moderation trail.
  Future<RealEstatePropertyModel?> property(String id) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.executiveProperty, <String, String>{'id': id}),
    );
    return _single(body, RealEstatePropertyModel.fromJson);
  }
}
