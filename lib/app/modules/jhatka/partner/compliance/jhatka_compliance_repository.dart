/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 *
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:partner/app/modules/jhatka/jhatka_endpoints.dart';

/// Compliance surface: FSSAI record, complaints, reviews, promotions.
///
/// Status is derived server side, never asserted by a human — this screen
/// renders what the server derives. A response, once written, cannot be
/// rewritten (reviews) or appends to the trail (complaints).
class JhatkaComplianceRepository {
  JhatkaComplianceRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  Future<DioApiResponse> status() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.compliance,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Submit (or resubmit) the FSSAI licence. Goes to `pending` — approval
  /// is the compliance officer's, not the submitter's.
  Future<DioApiResponse> submitFssai({
    required String licenceNumber,
    required String expiresAt,
    String? documentUrl,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'licenceNumber': licenceNumber,
      'expiresAt': expiresAt,
    };
    if (documentUrl != null) body['documentUrl'] = documentUrl;
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.complianceFssai,
      method: 'POST',
      token: await _authRepository.authToken(),
      body: body,
    );
  }

  Future<DioApiResponse> complaints() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.complaints,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Append a response and optionally move status. Either field may be sent
  /// alone; sending neither is a no-op the server accepts.
  Future<DioApiResponse> respondComplaint({
    required String complaintId,
    String? response,
    String? status,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (response != null) body['response'] = response;
    if (status != null) body['status'] = status;
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.complaintRespond,
        <String, String>{'id': complaintId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: body,
    );
  }

  Future<DioApiResponse> reviews() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.reviews,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Owner-only, and exactly once — a responded review refuses a second one.
  Future<DioApiResponse> respondReview({
    required String reviewId,
    required String response,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.reviewRespond,
        <String, String>{'id': reviewId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'response': response},
    );
  }

  Future<DioApiResponse> promotions() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.promotions,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Create a promotion. Owner-only server-side; code must be unique per outlet.
  /// `value` is in the promotion's own units (percent or paise by `type`) — the
  /// server validates the shape, so this passes numbers through untouched.
  Future<DioApiResponse> createPromotion({
    required String code,
    required String name,
    required String type,
    required num value,
    String? description,
    num? minOrderValuePaise,
    num? maxDiscountPaise,
    int? usageLimit,
    String? validFrom,
    String? validUntil,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.promotions,
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'code': code,
        'name': name,
        'type': type,
        'value': value,
        if (description case final descriptionValue)
          'description': descriptionValue,
        if (minOrderValuePaise case final minOrderValuePaiseValue)
          'minOrderValuePaise': minOrderValuePaiseValue,
        if (maxDiscountPaise case final maxDiscountPaiseValue)
          'maxDiscountPaise': maxDiscountPaiseValue,
        if (usageLimit case final usageLimitValue)
          'usageLimit': usageLimitValue,
        if (validFrom case final validFromValue) 'validFrom': validFromValue,
        if (validUntil case final validUntilValue)
          'validUntil': validUntilValue,
      },
    );
  }

  /// Update outlet profile fields. Owner-only; partial — send only what changed.
  /// The server merges `settings` rather than replacing, so a screen editing the
  /// name cannot wipe the notification preferences.
  Future<DioApiResponse> updateOutlet({
    String? name,
    Map<String, dynamic>? address,
    String? phone,
    String? email,
    List<Map<String, dynamic>>? operatingHours,
    num? deliveryRadiusKm,
    Map<String, dynamic>? settings,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.complianceOutlet,
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        if (name case final nameValue) 'name': nameValue,
        if (address case final addressValue) 'address': addressValue,
        if (phone case final phoneValue) 'phone': phoneValue,
        if (email case final emailValue) 'email': emailValue,
        if (operatingHours case final operatingHoursValue)
          'operatingHours': operatingHoursValue,
        if (deliveryRadiusKm case final deliveryRadiusKmValue)
          'deliveryRadiusKm': deliveryRadiusKmValue,
        if (settings case final settingsValue) 'settings': settingsValue,
      },
    );
  }
}
