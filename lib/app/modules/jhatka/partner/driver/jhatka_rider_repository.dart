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

/// Rider calls. The rider is outlet staff using the Partner app (no
/// Deliveryman_app module, by design) under the driver role — a rider must
/// never hold partner authority, so these endpoints live in a separate
/// namespace with separate rights.
///
/// Every mutating call is idempotent where it matters: `clientRef` makes a
/// retried deliver return the ORIGINAL proof instead of a second one, and a
/// repeated collect returns the recorded collection.
class JhatkaRiderRepository {
  JhatkaRiderRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  Future<DioApiResponse> deliveries({bool activeOnly = true}) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.riderDeliveries,
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'active': activeOnly.toString()},
    );
  }

  Future<DioApiResponse> delivery(String deliveryId) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.riderDelivery,
        <String, String>{'delivery': deliveryId},
      ),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> _advance(String deliveryId, String step) async {
    final String template;
    switch (step) {
      case 'accept':
        template = JhatkaPartnerEndpoints.riderAccept;
      case 'pickup':
        template = JhatkaPartnerEndpoints.riderPickup;
      case 'arrived':
        template = JhatkaPartnerEndpoints.riderArrived;
      case 'out-for-delivery':
        template = JhatkaPartnerEndpoints.riderOutForDelivery;
      default:
        throw ArgumentError('Unknown delivery step $step');
    }
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(template, <String, String>{
        'delivery': deliveryId,
      }),
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> accept(String deliveryId) =>
      _advance(deliveryId, 'accept');

  Future<DioApiResponse> pickup(String deliveryId) =>
      _advance(deliveryId, 'pickup');

  Future<DioApiResponse> arrived(String deliveryId) =>
      _advance(deliveryId, 'arrived');

  Future<DioApiResponse> outForDelivery(String deliveryId) =>
      _advance(deliveryId, 'out-for-delivery');

  /// Complete the delivery. `clientRef` is required: without it a lift retry
  /// mints a second proof of one delivery.
  Future<DioApiResponse> deliver({
    required String deliveryId,
    required String clientRef,
    double? deliveredTempC,
    String? photo,
    String? otp,
    String? receiverName,
    num? codCollected,
    String? note,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{'clientRef': clientRef};
    if (photo != null) body['photo'] = photo;
    if (deliveredTempC != null) body['deliveredTempC'] = deliveredTempC;
    if (otp != null) body['otp'] = otp;
    if (receiverName != null) body['receiverName'] = receiverName;
    if (codCollected != null) body['codCollected'] = codCollected;
    if (note != null) body['note'] = note;
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.riderDeliver,
        <String, String>{'delivery': deliveryId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: body,
    );
  }

  /// Fail with a reason — it is what the outlet reads. `failed` is a
  /// first-class outcome, not an error to swallow.
  Future<DioApiResponse> fail({
    required String deliveryId,
    required String reason,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.riderFail,
        <String, String>{'delivery': deliveryId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'reason': reason},
    );
  }

  /// Capture proof of delivery standalone, idempotent on `clientRef`. A rider
  /// may photograph proof before the order is formally closed, and a retry
  /// must not create a second record.
  Future<DioApiResponse> capturePod({
    required String deliveryId,
    required String clientRef,
    String? photo,
    double? deliveredTempC,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'delivery': deliveryId,
      'clientRef': clientRef,
    };
    if (photo != null) body['photo'] = photo;
    if (deliveredTempC != null) body['deliveredTempC'] = deliveredTempC;
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.riderPod,
      method: 'POST',
      token: await _authRepository.authToken(),
      body: body,
    );
  }

  /// Record a COD collection. Retried posts return the recorded collection.
  Future<DioApiResponse> collectCod({
    required String deliveryId,
    required int amountPaise,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.riderCollectCod,
        <String, String>{'delivery': deliveryId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'amountPaise': amountPaise},
    );
  }

  Future<DioApiResponse> earnings() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.riderEarnings,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }
}
