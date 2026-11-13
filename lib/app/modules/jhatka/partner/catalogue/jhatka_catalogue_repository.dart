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

/// Catalogue browse plus outlet price overrides.
///
/// Overrides are bounded, approved, temporary departures from list price —
/// never silent repricings. Every create carries a reason (≥10 chars) and a
/// closed date range; beyond ±20% variance a *different* approver
/// (owner/manager) must activate.
class JhatkaCatalogueRepository {
  JhatkaCatalogueRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  Future<DioApiResponse> categories() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.catalogueCategories,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> products({String? category}) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.catalogueProducts,
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{if (category case final String c) 'category': c},
    );
  }

  Future<DioApiResponse> overrides() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.priceOverrides,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> createOverride({
    required String variant,
    required double pricePerUnit,
    String? priceBasis,
    required String effectiveFrom,
    required String effectiveTo,
    required String reason,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'variant': variant,
      'pricePerUnit': pricePerUnit,
      'effectiveFrom': effectiveFrom,
      'effectiveTo': effectiveTo,
      'reason': reason,
      if (priceBasis case final String basis) 'priceBasis': basis,
    };
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.priceOverrides,
      method: 'POST',
      token: await _authRepository.authToken(),
      body: body,
    );
  }

  Future<DioApiResponse> approveOverride(String overrideId) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.priceOverrideApprove,
        <String, String>{'override': overrideId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> revokeOverride(
    String overrideId,
    String revokeReason,
  ) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.priceOverrideRevoke,
        <String, String>{'override': overrideId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'revokeReason': revokeReason},
    );
  }
}
