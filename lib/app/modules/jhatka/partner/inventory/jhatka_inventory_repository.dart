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

/// Stock, batches and quarantine calls.
///
/// Quarantine and release both require a written reason — quarantining your
/// own stock is never a solo silent decision (§14.2: only compliance_officer,
/// manager and owner hold the gate).
class JhatkaInventoryRepository {
  JhatkaInventoryRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  /// Stock rows. `lowStockOnly` maps to `?lowStock=true`; `kind` is one of
  /// `raw`, `prepared`, `packaging`.
  Future<DioApiResponse> stock({
    bool lowStockOnly = false,
    String? kind,
  }) async {
    final Map<String, dynamic> query = <String, dynamic>{};
    if (lowStockOnly) query['lowStock'] = 'true';
    if (kind != null) query['kind'] = kind;
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.inventory,
      method: 'GET',
      token: await _authRepository.authToken(),
      body: query,
    );
  }

  Future<DioApiResponse> batches() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.batches,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> quarantineBatch({
    required String batchId,
    required String reason,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.batchQuarantine,
        <String, String>{'batch': batchId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'reason': reason},
    );
  }

  Future<DioApiResponse> releaseBatch({
    required String batchId,
    required String reason,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.batchRelease,
        <String, String>{'batch': batchId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'reason': reason},
    );
  }

  /// Open recalls for this outlet, newest first.
  Future<DioApiResponse> recalls() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.recalls,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Open a recall against a batch.
  ///
  /// `severity` is one of advisory, withdraw, recall — the server refuses anything
  /// else, because the severity decides whether customers are notified. `reason` is
  /// required and is what the outlet reads when the recall is reviewed.
  Future<DioApiResponse> openRecall({
    required String batchId,
    required String reason,
    required String severity,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.recalls,
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'batch': batchId,
        'reason': reason,
        'severity': severity,
      },
    );
  }

  /// Close a recall once the fan-out is done and the batch is resolved.
  Future<DioApiResponse> closeRecall({required String recallId}) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.recallClose,
        <String, String>{'recall': recallId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }

  /// The movement ledger. Filterable server-side; read-only — corrections go
  /// through adjust, which writes a NEW movement rather than editing history.
  Future<DioApiResponse> movements({
    String? inventoryItem,
    String? movementType,
    String? from,
    String? to,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.inventoryMovements,
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        if (inventoryItem case final inventoryItemValue)
          'inventoryItem': inventoryItemValue,
        if (movementType case final movementTypeValue)
          'movementType': movementTypeValue,
        if (from case final fromValue) 'from': fromValue,
        if (to case final toValue) 'to': toValue,
      },
    );
  }

  /// One stock line with its recent movements. Applies the same expired-batch
  /// rule as the list (zero available regardless of on-hand), so the two agree.
  Future<DioApiResponse> stockDetail(String itemId) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.inventoryItem,
        <String, String>{'id': itemId},
      ),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }
}
