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

/// Partner-side weighing calls. Every endpoint is guarded server side by
/// `weight.confirm` (Weigher role); the manager override additionally needs
/// `weight.override`. The outlet comes from the token — nothing to send.
///
/// A single weighing line. `actualQuantity` mirrors the API shape; the server
/// normalises units, so `900 GRAM` and `0.9 KG` are the same weighing (and a
/// retry with the same weights is reported back as `replayed: true`).
class WeighLineInput {
  const WeighLineInput({
    required this.orderItem,
    required this.actualValue,
    required this.actualUnit,
  });

  final String orderItem;
  final num actualValue;
  final String actualUnit;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'orderItem': orderItem,
    'actualQuantity': <String, dynamic>{
      'value': actualValue,
      'unit': actualUnit,
    },
  };
}

class JhatkaWeighRepository {
  JhatkaWeighRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  /// The order with its lines, estimates and lifecycle. Weighing is only
  /// offered when `lifecycle` is `PREPARING`, `WEIGHING` or `WEIGHT_CONFIRMED`
  /// (re-weigh); the server refuses the rest.
  Future<DioApiResponse> orderDetail(String orderId) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.orderDetail,
        <String, String>{'order': orderId},
      ),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Confirm weights. Returns the confirmations plus updated order totals.
  /// A 422 `WEIGHT_OVERRIDE_REQUIRED` means the overage passed the hard cap:
  /// show the override sheet and retry with [overrideReason].
  Future<DioApiResponse> weigh({
    required String orderId,
    required List<WeighLineInput> lines,
    Map<String, dynamic>? evidence,
    String? overrideReason,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'items': lines.map((WeighLineInput l) => l.toJson()).toList(),
    };
    if (evidence != null) body['evidence'] = evidence;
    if (overrideReason != null) {
      body['override'] = <String, dynamic>{'reason': overrideReason};
    }
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.orderWeigh,
        <String, String>{'order': orderId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: body,
    );
  }
}
