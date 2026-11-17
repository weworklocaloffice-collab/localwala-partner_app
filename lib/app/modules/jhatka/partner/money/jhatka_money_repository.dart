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

/// Settlements, payouts and payables.
///
/// Money arrives in mixed units by endpoint — the settlement summary speaks
/// paise (`totalRevenuePaise`), and so do the lean payouts/payables lists
/// (raw paise, NOT moneyField getters) — so every screen formats through
/// `jhatka_money` with the unit made explicit at the call site. Only the
/// analytics service returns rupees (it converts at its own boundary). A
/// payout below `minimumNetPayout` is not paid but rolled forward; the row
/// says so itself (`rolledForwardReason`).
class JhatkaMoneyRepository {
  JhatkaMoneyRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  Future<DioApiResponse> settlementSummary({
    required String fromDate,
    required String toDate,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.settlementSummary,
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'fromDate': fromDate, 'toDate': toDate},
    );
  }

  Future<DioApiResponse> payouts() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.payouts,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> payables() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.payables,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// The outlet's effective commission terms, the rule last applied at payout,
  /// and the last payout period. A partner cannot create or edit the rule.
  Future<DioApiResponse> commissionTerms() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.commissionTerms,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Outlet dashboard summary: orders, wastage, subscriptions, inventory.
  Future<DioApiResponse> analytics() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.outletAnalytics,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// One payout with its lines and rule snapshot. The list carries totals;
  /// only the detail carries what produced them.
  Future<DioApiResponse> payoutDetail(String payoutId) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.payoutDetail,
        <String, String>{'id': payoutId},
      ),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Platform settlements for this outlet. Read-only from here — finalise and
  /// dispute are admin actions, and a partner screen that could do either would
  /// be a second writer on money it does not own.
  Future<DioApiResponse> settlements() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.settlements,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }
}
