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

/// The partner side of stock supply (OD-12 companion): request stock from
/// LocalWala, see requests and the prepaid ledger, pay a prepaid request.
///
/// The server computes which payment modes this outlet may use — the UI renders
/// `GET /modes`'s list and never guesses. Approval and fulfilment are admin
/// acts; this repository only creates, lists and pays.
class JhatkaSupplyRepository {
  JhatkaSupplyRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  Future<DioApiResponse> catalogue() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.supplyCatalogue,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Which payment modes this outlet may use right now, and why not the others.
  Future<DioApiResponse> modes() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.supplyModes,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> createRequest({
    required List<Map<String, dynamic>> items,
    String? neededBy,
    String? note,
    required String paymentMode,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.supplyRequests,
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'items': items,
        'paymentMode': paymentMode,
        if (neededBy != null && neededBy.isNotEmpty) 'neededBy': neededBy,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }

  Future<DioApiResponse> listRequests({String? status}) async {
    return ApiRequestService.makeRequest(
      status == null || status.isEmpty
          ? JhatkaPartnerEndpoints.supplyRequests
          : '${JhatkaPartnerEndpoints.supplyRequests}?status=$status',
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> ledger() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.supplyLedger,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Current delivery rings + the platform ceiling + any open request.
  ///
  /// Money in this payload is PAISE (lean reads throughout the vertical) — the
  /// screen formats it, never divides ad hoc.
  Future<DioApiResponse> area() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.supplyArea,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Propose new rings. `extendedDeliveryFee` is RUPEES at this edge — the
  /// server's moneyField stores paise. The admin approves before anything
  /// changes; a proposal beyond the platform ceiling is refused on the spot.
  Future<DioApiResponse> createAreaRequest({
    required double radiusKm,
    required double extendedRadiusKm,
    required double extendedDeliveryFee,
    required String reason,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.supplyAreaRequests,
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'proposed': <String, dynamic>{
          'radiusKm': radiusKm,
          'extendedRadiusKm': extendedRadiusKm,
          'extendedDeliveryFee': extendedDeliveryFee,
        },
        'reason': reason,
      },
    );
  }

  /// Withdraw a still-open proposal.
  Future<DioApiResponse> cancelAreaRequest(String requestId) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.supplyAreaRequest,
        <String, String>{'id': requestId},
      ),
      method: 'DELETE',
      token: await _authRepository.authToken(),
    );
  }

  /// Prepay an APPROVED request: returns a PaymentInitiation for the shared
  /// checkout to complete. The verified callback marks the request paid.
  Future<DioApiResponse> pay({required String requestId}) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.supplyRequestPay,
        <String, String>{'id': requestId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }
}
