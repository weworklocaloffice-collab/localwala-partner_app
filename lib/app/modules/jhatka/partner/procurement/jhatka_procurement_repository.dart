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

/// Suppliers, purchase orders and receipts.
///
/// Posting is idempotent-by-conflict: a posted receipt refused with 409, and
/// a receipt whose line fails validation rolls the whole posting back — the
/// screen reports the refusal and reloads rather than guessing state.
class JhatkaProcurementRepository {
  JhatkaProcurementRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  Future<DioApiResponse> suppliers() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.suppliers,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> purchaseOrders() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.purchaseOrders,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> placeOrder(String poId) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.purchaseOrderPlace,
        <String, String>{'po': poId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> receipts() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.receipts,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// The controlled vocabulary for the receipt rejection picker.
  Future<DioApiResponse> rejectionReasons() async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.rejectionReasons,
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Accept one pending line. The face value is the received quantity, so the
  /// server makes that quantity saleable and payable when the receipt posts.
  Future<DioApiResponse> acceptReceiptLine(
    String receiptId,
    int lineIndex, {
    String? note,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.receiptAccept,
        <String, String>{'receipt': receiptId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'lineIndex': lineIndex,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }

  /// Reject one pending line with governed reason codes. A line that already
  /// owns a batch is refused by the server with `REVERSE_BATCH_FIRST`.
  Future<DioApiResponse> rejectReceiptLine(
    String receiptId,
    int lineIndex,
    List<String> reasonCodes, {
    String? note,
  }) async {
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.receiptReject,
        <String, String>{'receipt': receiptId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'lineIndex': lineIndex,
        'rejectionReasons': reasonCodes
            .map((String code) => <String, String>{'code': code})
            .toList(growable: false),
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }

  /// Post a draft receipt: batches, stock, ledger and allocations commit
  /// together, and the purchase order advances. `expiresAtByLine` optionally
  /// pins per-line expiries (supplier printed dates).
  Future<DioApiResponse> postReceipt(
    String receiptId, {
    Map<String, String>? expiresAtByLine,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{};
    if (expiresAtByLine != null) body['expiresAtByLine'] = expiresAtByLine;
    return ApiRequestService.makeRequest(
      JhatkaPartnerEndpoints.resolve(
        JhatkaPartnerEndpoints.receiptPost,
        <String, String>{'receipt': receiptId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: body,
    );
  }
}
