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

/// Stock-write calls: receipts, manual adjustments, wastage.
///
/// Every one of these moves the ledger, so every one returns the resulting
/// balance and the screen reloads from it — never from a locally computed
/// guess. Reductions without a linked cause need owner authority server
/// side (`wastage.adjust`); the screen does not second-guess 403s.
class JhatkaStockRepository {
  JhatkaStockRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  static const List<String> manualMovementTypes = <String>[
    'ADJUSTMENT',
    'COUNT_ADJUSTMENT',
    'STOCK_IN',
    'RETURN',
    'TRANSFER',
  ];

  static const List<String> wastageCauses = <String>[
    'TRIM',
    'SPOILAGE',
    'EXPIRY',
    'OVER_PREPARATION',
    'CUSTOMER_REJECTED',
    'QUALITY_REJECTION',
    'PACKAGING_DAMAGE',
    'THEFT_LOSS',
    'OTHER',
  ];

  /// Draft a receipt. Quality is evaluated server side per line; stock moves
  /// only when the receipt is POSTED, so a delivery can be inspected first.
  Future<DioApiResponse> createReceipt({
    String? purchaseOrder,
    required String supplier,
    String? supplierInvoiceRef,
    required List<Map<String, dynamic>> lines,
    String? vehicleNo,
    String? note,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'supplier': supplier,
      'lines': lines,
    };
    if (purchaseOrder != null) body['purchaseOrder'] = purchaseOrder;
    if (supplierInvoiceRef != null) {
      body['supplierInvoiceRef'] = supplierInvoiceRef;
    }
    if (vehicleNo != null) body['vehicleNo'] = vehicleNo;
    if (note != null) body['note'] = note;
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.receiptsCreate,
      method: 'POST',
      token: await _authRepository.authToken(),
      body: body,
    );
  }

  /// Manual correction. `movementType` is chosen, never inferred:
  /// ADJUSTMENT and COUNT_ADJUSTMENT mean different things downstream.
  Future<DioApiResponse> adjust({
    required String inventoryItem,
    num? qtyDelta,
    num? reservedDelta,
    required String movementType,
    required String reason,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'inventoryItem': inventoryItem,
      'movementType': movementType,
      'reason': reason,
    };
    if (qtyDelta != null) body['qtyDelta'] = qtyDelta;
    if (reservedDelta != null) body['reservedDelta'] = reservedDelta;
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.inventoryAdjust,
      method: 'POST',
      token: await _authRepository.authToken(),
      body: body,
    );
  }

  /// Record wastage with its cause. `THEFT_LOSS` needs an owner; the server
  /// refuses the rest, and the screen shows the refusal as-is.
  Future<DioApiResponse> recordWastage({
    required String inventoryItem,
    required num qty,
    required String unit,
    required String cause,
    String? notes,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'inventoryItem': inventoryItem,
      'qty': qty,
      'unit': unit,
      'cause': cause,
    };
    if (notes != null) body['notes'] = notes;
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.inventoryWastage,
      method: 'POST',
      token: await _authRepository.authToken(),
      body: body,
    );
  }
}
