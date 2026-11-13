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

/// Multi-outlet session: which counters this login may work, and which is active.
///
/// BR-04 — one business may operate many outlets. The server derives tenancy from
/// the access token, so switching is a server call (`POST /session/outlet`), not a
/// client-side variable: a client that could switch by setting a string could reach
/// any outlet. The list carries compliance per outlet so the picker shows WHY a
/// counter cannot be worked, not just that it cannot.
class JhatkaSessionRepository {
  JhatkaSessionRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  /// Counters this login may work, with status and compliance each.
  Future<DioApiResponse> outlets() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.sessionOutlets,
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }

  /// Switch the active counter. Persists server-side as `lastActiveOutletId`, so
  /// the next login opens here. A suspended counter refuses non-owner/manager
  /// roles — the server decides, and the refusal names the status.
  Future<DioApiResponse> switchOutlet({required String outletId}) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.sessionSwitch,
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'outletId': outletId},
    );
  }

  /// Current scope: active outlet, role, permitted ids.
  Future<DioApiResponse> scope() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.sessionScope,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }
}
