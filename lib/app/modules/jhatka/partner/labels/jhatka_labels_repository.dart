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

/// Food-safety label console calls.
///
/// A label moves draft → printed → applied; voiding needs a written reason.
/// The FSSAI licence, use-by and trace batch all come from the server —
/// there is deliberately no field for the caller to override them.
class JhatkaLabelsRepository {
  JhatkaLabelsRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  Future<DioApiResponse> labels() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.labels,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> print(String labelId) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.labelPrint,
        <String, String>{'label': labelId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> apply(String labelId) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.labelApply,
        <String, String>{'label': labelId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> voidLabel(String labelId, String reason) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.labelVoid,
        <String, String>{'label': labelId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'reason': reason},
    );
  }

  /// Generate the label set for an order. Commits together server-side — a
  /// five-line order whose fourth line has no expiry fails whole, not four
  /// labels plus a 409. `items` carries order-item ids; omit it for the whole
  /// order.
  Future<DioApiResponse> create({
    required String orderId,
    List<String>? items,
    String? storageInstruction,
    String? customerCare,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.labels,
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'order': orderId,
        if (items case final itemsValue) 'items': itemsValue,
        if (storageInstruction case final storageInstructionValue)
          'storageInstruction': storageInstructionValue,
        if (customerCare case final customerCareValue)
          'customerCare': customerCareValue,
      },
    );
  }

  /// One label with its trace: batch, use-by, QR payload.
  Future<DioApiResponse> detail(String labelId) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.labelDetail,
        <String, String>{'label': labelId},
      ),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }
}
