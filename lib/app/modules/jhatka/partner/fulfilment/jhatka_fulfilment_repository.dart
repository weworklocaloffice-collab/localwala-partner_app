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

/// Pack → ready → dispatch calls, plus the intake that precedes them.
///
/// The server guards every step: pack needs `packing.complete` and weighed
/// lines (409 `WEIGHT_NOT_CONFIRMED`); ready refuses a packing cold-chain
/// breach (409 `COLD_CHAIN_BREACH`); dispatch needs an outlet-owned active
/// rider (403 otherwise) and refuses past the transit limit (409
/// `MAX_TRANSIT_EXCEEDED`). Error codes are surfaced, not swallowed, because
/// each one tells the dispatcher a different next action.
///
/// Intake (receive → accept → reject / prepare) lives here too — it is the first
/// half of the same pipeline. It was added late because the backend's
/// OUTLET_RECEIVED state itself had no writer until the lifecycle audit found it,
/// so for a while the app went list → weigh with nothing in between and every new
/// order sat at CREATED forever.
class JhatkaFulfilmentRepository {
  JhatkaFulfilmentRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  /// Riders of this outlet with eligibility spelled out.
  Future<DioApiResponse> outletDrivers() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.outletDrivers,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Receive: the outlet acknowledges the order is on its screen.
  ///
  /// Where the outlet's SLA clock starts. COD orders arrive from CREATED,
  /// gateway orders from PAID — the server's table decides, not this call.
  /// A lapsed outlet is refused (403): taking on is new business.
  Future<DioApiResponse> receive({required String orderId}) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.orderReceive,
        <String, String>{'order': orderId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }

  /// Accept: the outlet commits to fulfilling.
  ///
  /// Same compliance rule as receive — accepting takes the order onto the
  /// counter, so an outlet whose documents lapsed overnight may not do it for
  /// this morning's queue.
  Future<DioApiResponse> accept({required String orderId}) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.orderAccept,
        <String, String>{'order': orderId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }

  /// Reject: refuse the order with a reason the customer reads.
  ///
  /// For a paid order the server raises the refund as a document and moves the
  /// order toward REFUND_PENDING — the response carries it, so the screen can
  /// show what the customer gets back rather than just "rejected".
  Future<DioApiResponse> reject({
    required String orderId,
    required String reason,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.orderReject,
        <String, String>{'order': orderId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'reason': reason},
    );
  }

  /// Start preparation: opens the cutting ticket and allocates real stock.
  ///
  /// Refused with INSUFFICIENT_RAW_STOCK when the counter cannot cover the
  /// order — the screen must show the shortfall SKUs, not a bare failure,
  /// because "we don't have it" and "the app broke" need different next steps.
  /// `items` carries the lines to cut; omit it and the server prepares every
  /// line on the order.
  Future<DioApiResponse> startPreparation({
    required String orderId,
    List<Map<String, dynamic>>? items,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.orderStartPreparation,
        <String, String>{'order': orderId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        if (items case final List<Map<String, dynamic>> lines) 'items': lines,
      },
    );
  }

  /// Pack. `coldChainTempC` null means no temperature was taken; a breach is
  /// recorded only when a reading exists and is out of band — the screen asks
  /// for the reading, the server decides the band.
  Future<DioApiResponse> pack({
    required String orderId,
    int? packageCount,
    int? totalWeightGrams,
    double? coldChainTempC,
    String? breachReason,
    bool? fragile,
    String? note,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (packageCount case final int count) body['packageCount'] = count;
    if (totalWeightGrams case final int grams) {
      body['totalWeightGrams'] = grams;
    }
    if (coldChainTempC case final double temp) {
      body['coldChain'] = <String, dynamic>{
        'tempC': temp,
        if (breachReason case final String reason) 'breachReason': reason,
      };
    }
    if (fragile != null) body['fragile'] = fragile;
    if (note != null) body['note'] = note;
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.orderPack,
        <String, String>{'order': orderId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: body,
    );
  }

  Future<DioApiResponse> markReady(String orderId) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.orderReady,
        <String, String>{'order': orderId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }

  /// Update a rider's name, mobile or vehicle. Status moves through
  /// [setDriverStatus] so every change carries its reason.
  Future<DioApiResponse> updateDriver({
    required String driverId,
    String? name,
    num? mobile,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (mobile != null) body['mobile'] = mobile;
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.outletDriverUpdate,
        <String, String>{'driver': driverId},
      ),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: body,
    );
  }

  /// Move a rider between active/inactive/suspended. Never deleted (BR-24).
  Future<DioApiResponse> setDriverStatus({
    required String driverId,
    required String status,
    String? reason,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{'status': status};
    if (reason != null) body['reason'] = reason;
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.outletDriverStatus,
        <String, String>{'driver': driverId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: body,
    );
  }

  /// In-flight deliveries for the outlet (`?active=true` narrows).
  Future<DioApiResponse> deliveries({bool activeOnly = true}) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.outletDeliveries,
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'active': activeOnly.toString()},
    );
  }

  /// One delivery with its order lines and POD. The POD carries the
  /// delivered temperature and any cold-chain breach — theProof the
  /// customer received safe meat, or the record that they did not.
  Future<DioApiResponse> deliveryDetail(String deliveryId) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.outletDeliveryDetail,
        <String, String>{'delivery': deliveryId},
      ),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> dispatch({
    required String orderId,
    required String driverId,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.orderDispatch,
        <String, String>{'order': orderId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'driver': driverId},
    );
  }

  /// Collect: the counter hand-over for a PICKUP order (OD-12) — READY →
  /// COMPLETED with no rider and no delivery document. The mirror of dispatch
  /// and mutually exclusive with it: the server refuses a delivery order here
  /// (409 DELIVERY_ORDER) just as dispatch refuses a pickup one. The OTP is
  /// the same code the rider flow verifies — pass it when the customer reads
  /// one out; omit it for a known-face hand-over.
  Future<DioApiResponse> collect({required String orderId, String? otp}) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.orderCollect,
        <String, String>{'order': orderId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: otp == null ? null : <String, dynamic>{'otp': otp},
    );
  }
}
