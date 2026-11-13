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

/// Subscription console calls.
///
/// Pause, cancel and item changes all require a written reason — "why did my
/// subscription change its own mind" must stay answerable from the event
/// trail. Skipping the next occurrence needs no reason; it is not a state.
class JhatkaSubscriptionsRepository {
  JhatkaSubscriptionsRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  Future<DioApiResponse> subscriptions() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.subscriptions,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> pause(String subscriptionId, String reason) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.subscriptionPause,
        <String, String>{'subscription': subscriptionId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'reason': reason},
    );
  }

  Future<DioApiResponse> resume(String subscriptionId) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.subscriptionResume,
        <String, String>{'subscription': subscriptionId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> cancel(String subscriptionId, String reason) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.subscriptionCancel,
        <String, String>{'subscription': subscriptionId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'reason': reason},
    );
  }

  Future<DioApiResponse> skipNext(String subscriptionId) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.subscriptionSkip,
        <String, String>{'subscription': subscriptionId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }

  /// Manual generation for one date (yyyy-mm-dd). Idempotent per
  /// subscription+date: a second call replays, it never duplicates.
  Future<DioApiResponse> generateOccurrence({
    required String subscriptionId,
    required String occurrenceDate,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.occurrenceGenerate,
        <String, String>{'occurrence': subscriptionId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'occurrenceDate': occurrenceDate},
    );
  }

  /// Full detail: the subscription, its event trail, and upcoming occurrences —
  /// including billing state per occurrence, which the list does not carry.
  Future<DioApiResponse> detail(String subscriptionId) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.subscriptionDetail,
        <String, String>{'subscription': subscriptionId},
      ),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Change the standing items. The server enforces `editCutoffHours` — this call
  /// fails near a delivery, and the failure names the cutoff rather than "error".
  Future<DioApiResponse> updateItems({
    required String subscriptionId,
    required List<Map<String, dynamic>> items,
    required String reason,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.subscriptionItems,
        <String, String>{'subscription': subscriptionId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'items': items, 'reason': reason},
    );
  }

  /// Retry a prepaid charge that never arrived.
  ///
  /// Mints a FRESH initiation and notifies the customer. It does NOT mark anything
  /// paid — only a gateway callback does that — so the screen must say "charge
  /// restarted", never "paid". The response names the action; anything other than
  /// `charged` means there was nothing to retry.
  Future<DioApiResponse> retryBilling({required String occurrenceId}) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.occurrenceRetryBilling,
        <String, String>{'occurrence': occurrenceId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }

  /// Search THIS outlet's customers by name or phone.
  ///
  /// Scoped server-side to customers with an order here — never platform-wide.
  /// Needs 2+ characters; an empty query is refused, not dumped.
  Future<DioApiResponse> searchCustomers(String query) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.customerSearch,
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'q': query},
    );
  }

  /// Create a subscription on behalf of a customer.
  ///
  /// The server enforces the egg rule and the ceiling; the app collects customer,
  /// items, schedule and start date. The outlet comes from the token server-side —
  /// nothing about tenancy travels in the body. `customerId` comes from
  /// [searchCustomers] — never typed freehand, because a mistyped id subscribes
  /// a stranger.
  Future<DioApiResponse> create({
    required String customerId,
    required List<Map<String, dynamic>> items,
    required String scheduleType,
    required String startDate,
    List<int>? customDays,
    String? endDate,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.subscriptions,
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'customer': customerId,
        'items': items,
        'scheduleType': scheduleType,
        'startDate': startDate,
        if (customDays case final List<int> days) 'customDays': days,
        if (endDate case final String end) 'endDate': end,
      },
    );
  }
}
