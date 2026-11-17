/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:partner/app/core/config/api_endpoints.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/config/realestate_endpoints.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:partner/app/modules/realestate/models/commission.dart';
import 'package:partner/app/modules/realestate/models/geo_option.dart';
import 'package:partner/app/modules/realestate/models/hold.dart';
import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/app/modules/realestate/models/lead_detail.dart';
import 'package:partner/app/modules/realestate/models/listing_entitlement.dart';
import 'package:partner/app/modules/realestate/models/listing_order.dart';
import 'package:partner/app/modules/realestate/models/listing_package.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/models/property_category.dart';
import 'package:partner/app/modules/realestate/models/property_document.dart';
import 'package:partner/app/modules/realestate/models/sale.dart';
import 'package:partner/app/modules/realestate/models/visit.dart';

/// Thrown when a Real Estate call fails at the transport or API layer.
///
/// `statusCode` is the HTTP status when one arrived (401/403/404/422 carry
/// meaning for the blocs: re-login, not-permitted, missing, invalid).
class RealEstateApiException implements Exception {
  final String message;
  final int? statusCode;

  const RealEstateApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'RealEstateApiException($statusCode): $message';
}

/// One page of a list endpoint.
class RealEstatePage<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;

  const RealEstatePage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });
}

/// Vendor surface of the Real Estate module (`/v1/realestate/vendor`).
///
/// Returns parsed models; transport/API failures throw
/// [RealEstateApiException] for the blocs to render. Query parameters
/// travel in the URL — the list validations declare `query`, and a GET
/// body never reaches `req.query`.
///
/// Money arrives in rupees on every edge (money-edges gate); the models
/// parse it as-is, with no paise conversion anywhere in this folder.
class RealEstateVendorRepository {
  RealEstateVendorRepository({AuthRepository? authRepository})
    : _auth = authRepository ?? AuthRepository();

  final AuthRepository _auth;

  String _path(
    String template, [
    Map<String, String> values = const <String, String>{},
  ]) {
    return RealEstateEndpoints.resolve(template, values);
  }

  String _qs(Map<String, String?> params) {
    final String q = params.entries
        .where(
          (MapEntry<String, String?> e) =>
              e.value != null && e.value!.isNotEmpty,
        )
        .map(
          (MapEntry<String, String?> e) =>
              '${e.key}=${Uri.encodeComponent(e.value!)}',
        )
        .join('&');
    return q.isEmpty ? '' : '?$q';
  }

  Never _fail(DioApiResponse response, String action) {
    final Map<String, dynamic> body = decodeBody(response);
    final dynamic message = body['message'] ?? body['error'];
    throw RealEstateApiException(
      message?.toString() ?? '$action failed',
      response.statusCode,
    );
  }

  Future<Map<String, dynamic>> _getMap(String url) async {
    final DioApiResponse response = await ApiRequestService.makeRequest(
      url,
      method: 'GET',
      token: await _auth.authToken(),
    );
    if (response.errorType != NetErrorType.none) _fail(response, 'GET $url');
    return decodeBody(response);
  }

  Future<Map<String, dynamic>> _mutate(
    String url, {
    required String method,
    Map<String, dynamic>? body,
  }) async {
    final DioApiResponse response = await ApiRequestService.makeRequest(
      url,
      method: method,
      token: await _auth.authToken(),
      body: body,
    );
    if (response.errorType != NetErrorType.none) {
      _fail(response, '$method $url');
    }
    return decodeBody(response);
  }

  RealEstatePage<T> _page<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) parse, {
    int page = 1,
    int limit = 20,
  }) {
    final List<dynamic> raw = body['results'] is List
        ? body['results'] as List<dynamic>
        : const <dynamic>[];
    final List<T> items = raw
        .whereType<Map>()
        .map((Map m) => parse(Map<String, dynamic>.from(m)))
        .toList();
    final dynamic total = body['total'] ?? body['totalResults'];
    return RealEstatePage<T>(
      items: items,
      page: body['page'] is num ? (body['page'] as num).toInt() : page,
      limit: body['limit'] is num ? (body['limit'] as num).toInt() : limit,
      total: total is num ? total.toInt() : items.length,
    );
  }

  T? _single<T>(
    Map<String, dynamic> body,
    T Function(Map<String, dynamic>) parse,
  ) {
    final dynamic data = body['data'];
    if (data is Map) return parse(Map<String, dynamic>.from(data));
    return null;
  }

  //// Self ////

  /// Registers the signed-in user as a vendor. The payload carries the
  /// business/KYC/bank fields; the server links the row to the user.
  Future<Map<String, dynamic>> registerVendor(
    Map<String, dynamic> payload,
  ) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.vendorRegister),
      method: 'POST',
      body: payload,
    );
    return _single(body, (Map<String, dynamic> m) => m) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> me() async {
    return _single(
          await _getMap(_path(RealEstateEndpoints.vendorMe)),
          (Map<String, dynamic> m) => m,
        ) ??
        <String, dynamic>{};
  }

  Future<Map<String, dynamic>> submitForReview() async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.vendorSubmitForReview),
      method: 'POST',
    );
    return _single(body, (Map<String, dynamic> m) => m) ?? <String, dynamic>{};
  }

  Future<Map<String, dynamic>> dashboard() async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.vendorDashboard),
    );
    final dynamic data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  //// Packages and orders (BR-02, BR-05) ////

  Future<List<RealEstatePackageModel>> packages() async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.vendorPackages),
    );
    final List<dynamic> raw = body['results'] is List
        ? body['results'] as List<dynamic>
        : const <dynamic>[];
    return raw
        .whereType<Map>()
        .map(
          (Map m) =>
              RealEstatePackageModel.fromJson(Map<String, dynamic>.from(m)),
        )
        .toList();
  }

  Future<RealEstatePackageModel?> package(String code) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.vendorPackage, <String, String>{'code': code}),
    );
    return _single(body, RealEstatePackageModel.fromJson);
  }

  Future<RealEstateOrderModel?> purchasePackage(String code) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.vendorPackagePurchase, <String, String>{
        'code': code,
      }),
      method: 'POST',
    );
    return _single(body, RealEstateOrderModel.fromJson);
  }

  Future<RealEstatePage<RealEstateOrderModel>> orders({
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.vendorOrders)}${_qs(<String, String?>{'page': page.toString(), 'limit': limit.toString()})}',
    );
    return _page(body, RealEstateOrderModel.fromJson, page: page, limit: limit);
  }

  Future<RealEstateOrderModel?> order(String id) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.vendorOrder, <String, String>{'id': id}),
    );
    return _single(body, RealEstateOrderModel.fromJson);
  }

  Future<RealEstateOrderModel?> cancelOrder(String id, {String? reason}) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.vendorOrderCancel, <String, String>{'id': id}),
      method: 'POST',
      body: reason != null && reason.isNotEmpty
          ? <String, dynamic>{'reason': reason}
          : null,
    );
    return _single(body, RealEstateOrderModel.fromJson);
  }

  /// Starts (or resumes) the gateway handoff for an unpaid order. The server
  /// owns the amount; `payLink` is the initiation id, never a gateway order.
  Future<RealEstateOrderPayment?> payOrder(
    String id, {
    String? paymentConfigId,
  }) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.vendorOrderPay, <String, String>{'id': id}),
      method: 'POST',
      body: paymentConfigId == null || paymentConfigId.isEmpty
          ? null
          : <String, dynamic>{'payment': paymentConfigId},
    );
    final RealEstateOrderPayment payment = RealEstateOrderPayment.fromJson(
      body,
    );
    return payment.payLink == null || payment.payLink!.isEmpty ? null : payment;
  }

  /// Gateway order payload for the checkout SDK. `amount` is paise here,
  /// because Razorpay expects minor units - do not divide it.
  Future<Map<String, dynamic>> paymentOrder(String payLink) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.paymentMake, <String, String>{'id': payLink}),
    );
    if (body['success'] != true ||
        body['key'] == null ||
        body['order_id'] == null) {
      throw const RealEstateApiException(
        'Payment gateway is not available right now',
      );
    }
    return body;
  }

  /// Server-side HMAC verification; only the API can grant the entitlement.
  Future<void> verifyPayment(
    String payLink, {
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.paymentSuccess, <String, String>{
        'id': payLink,
      }),
      method: 'POST',
      body: <String, dynamic>{
        'razorpay_payment_id': paymentId,
        'razorpay_order_id': orderId,
        'razorpay_signature': signature,
      },
    );
    if (body['success'] != true) {
      throw RealEstateApiException(
        body['message']?.toString() ?? 'Payment verification failed',
      );
    }
  }

  Future<List<RealEstateEntitlementModel>> entitlements() async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.vendorEntitlements),
    );
    final List<dynamic> raw = body['results'] is List
        ? body['results'] as List<dynamic>
        : const <dynamic>[];
    return raw
        .whereType<Map>()
        .map(
          (Map m) =>
              RealEstateEntitlementModel.fromJson(Map<String, dynamic>.from(m)),
        )
        .toList();
  }

  //// Properties ////

  Future<RealEstatePropertyModel?> createProperty(
    Map<String, dynamic> payload,
  ) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.vendorProperties),
      method: 'POST',
      body: payload,
    );
    return _single(body, RealEstatePropertyModel.fromJson);
  }

  Future<RealEstatePage<RealEstatePropertyModel>> properties({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.vendorProperties)}${_qs(<String, String?>{'page': page.toString(), 'limit': limit.toString(), 'status': status})}',
    );
    return _page(
      body,
      RealEstatePropertyModel.fromJson,
      page: page,
      limit: limit,
    );
  }

  Future<RealEstatePropertyModel?> property(String id) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.vendorProperty, <String, String>{'id': id}),
    );
    return _single(body, RealEstatePropertyModel.fromJson);
  }

  Future<RealEstatePropertyModel?> updateProperty(
    String id,
    Map<String, dynamic> changes,
  ) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.vendorProperty, <String, String>{'id': id}),
      method: 'PATCH',
      body: changes,
    );
    return _single(body, RealEstatePropertyModel.fromJson);
  }

  Future<RealEstatePropertyModel?> submitProperty(String id) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.vendorPropertySubmit, <String, String>{
        'id': id,
      }),
      method: 'POST',
    );
    return _single(body, RealEstatePropertyModel.fromJson);
  }

  Future<RealEstatePropertyModel?> withdrawProperty(String id) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.vendorPropertyWithdraw, <String, String>{
        'id': id,
      }),
      method: 'POST',
    );
    return _single(body, RealEstatePropertyModel.fromJson);
  }

  Future<RealEstatePropertyModel?> changePropertyStatus(
    String id,
    String status, {
    String? reason,
  }) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.vendorPropertyStatus, <String, String>{
        'id': id,
        'status': status,
      }),
      method: 'POST',
      body: reason != null && reason.isNotEmpty
          ? <String, dynamic>{'reason': reason}
          : null,
    );
    return _single(body, RealEstatePropertyModel.fromJson);
  }

  //// Documents (BR-18, BR-21) ////

  Future<RealEstateDocumentModel?> uploadDocument(
    String propertyId,
    Map<String, dynamic> payload,
  ) async {
    final Map<String, dynamic> body = await _mutate(
      _path(RealEstateEndpoints.vendorPropertyDocuments, <String, String>{
        'id': propertyId,
      }),
      method: 'POST',
      body: payload,
    );
    return _single(body, RealEstateDocumentModel.fromJson);
  }

  Future<List<RealEstateDocumentModel>> documents(String propertyId) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.vendorPropertyDocuments, <String, String>{
        'id': propertyId,
      }),
    );
    final List<dynamic> raw = body['results'] is List
        ? body['results'] as List<dynamic>
        : const <dynamic>[];
    return raw
        .whereType<Map>()
        .map(
          (Map m) =>
              RealEstateDocumentModel.fromJson(Map<String, dynamic>.from(m)),
        )
        .toList();
  }

  Future<RealEstateDocumentModel?> document(
    String propertyId,
    String documentId,
  ) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.vendorPropertyDocument, <String, String>{
        'id': propertyId,
        'documentId': documentId,
      }),
    );
    return _single(body, RealEstateDocumentModel.fromJson);
  }

  /// True when the server answered 204. ACCEPTED documents answer 409
  /// (as an exception) — they cannot be removed, only replaced.
  Future<bool> deleteDocument(String propertyId, String documentId) async {
    final DioApiResponse response = await ApiRequestService.makeRequest(
      _path(RealEstateEndpoints.vendorPropertyDocument, <String, String>{
        'id': propertyId,
        'documentId': documentId,
      }),
      method: 'DELETE',
      token: await _auth.authToken(),
    );
    if (response.errorType != NetErrorType.none) {
      _fail(response, 'DELETE document');
    }
    return true;
  }

  //// Pipeline (read-only) ////

  Future<RealEstatePage<RealEstateLeadModel>> leads({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.vendorLeads)}${_qs(<String, String?>{'page': page.toString(), 'limit': limit.toString(), 'status': status})}',
    );
    return _page(body, RealEstateLeadModel.fromJson, page: page, limit: limit);
  }

  Future<RealEstateLeadDetail?> lead(String id) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.vendorLead, <String, String>{'id': id}),
    );
    return _single(body, RealEstateLeadDetail.fromJson);
  }

  Future<RealEstatePage<RealEstateVisitModel>> visits({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.vendorVisits)}${_qs(<String, String?>{'page': page.toString(), 'limit': limit.toString(), 'status': status})}',
    );
    return _page(body, RealEstateVisitModel.fromJson, page: page, limit: limit);
  }

  Future<RealEstateVisitModel?> visit(String id) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.vendorVisit, <String, String>{'id': id}),
    );
    return _single(body, RealEstateVisitModel.fromJson);
  }

  Future<RealEstatePage<RealEstateHoldModel>> holds({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.vendorHolds)}${_qs(<String, String?>{'page': page.toString(), 'limit': limit.toString(), 'status': status})}',
    );
    return _page(body, RealEstateHoldModel.fromJson, page: page, limit: limit);
  }

  Future<RealEstatePage<RealEstateCustomerRef>> customers({
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.vendorCustomers)}${_qs(<String, String?>{'page': page.toString(), 'limit': limit.toString()})}',
    );
    return _page(
      body,
      RealEstateCustomerRef.fromJson,
      page: page,
      limit: limit,
    );
  }

  //// Analytics and money ////

  Future<Map<String, dynamic>> analytics() async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.vendorAnalytics),
    );
    final dynamic data = body['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  Future<RealEstatePage<RealEstateCommissionModel>> commissions({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.vendorCommissions)}${_qs(<String, String?>{'page': page.toString(), 'limit': limit.toString(), 'status': status})}',
    );
    return _page(
      body,
      RealEstateCommissionModel.fromJson,
      page: page,
      limit: limit,
    );
  }

  Future<RealEstatePage<RealEstateSaleModel>> sales({
    int page = 1,
    int limit = 20,
  }) async {
    final Map<String, dynamic> body = await _getMap(
      '${_path(RealEstateEndpoints.vendorSales)}${_qs(<String, String?>{'page': page.toString(), 'limit': limit.toString()})}',
    );
    return _page(body, RealEstateSaleModel.fromJson, page: page, limit: limit);
  }

  Future<RealEstateSaleModel?> sale(String id) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.vendorSale, <String, String>{'id': id}),
    );
    return _single(body, RealEstateSaleModel.fromJson);
  }

  //// Public catalogue (no session; the listing form's dropdowns) ////

  Future<List<RealEstateCategoryModel>> categories() async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.publicCategories),
    );
    final List<dynamic> raw = body['results'] is List
        ? body['results'] as List<dynamic>
        : const <dynamic>[];
    return raw
        .whereType<Map>()
        .map(
          (Map m) =>
              RealEstateCategoryModel.fromJson(Map<String, dynamic>.from(m)),
        )
        .toList();
  }

  Future<Map<String, List<RealEstateCategoryModel>>> groupedCategories() async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.publicCategoriesGrouped),
    );
    final dynamic groups = body['groups'];
    if (groups is! Map) return <String, List<RealEstateCategoryModel>>{};
    final Map<String, List<RealEstateCategoryModel>> out =
        <String, List<RealEstateCategoryModel>>{};
    groups.forEach((dynamic group, dynamic list) {
      out[group.toString()] = list is List
          ? list
                .whereType<Map>()
                .map(
                  (Map m) => RealEstateCategoryModel.fromJson(
                    Map<String, dynamic>.from(m),
                  ),
                )
                .toList()
          : <RealEstateCategoryModel>[];
    });
    return out;
  }

  /// One category with its filter descriptors. The response is unwrapped
  /// (no `data` envelope) by design.
  Future<RealEstateCategoryModel?> category(String key) async {
    final Map<String, dynamic> body = await _getMap(
      _path(RealEstateEndpoints.publicCategory, <String, String>{'key': key}),
    );
    if (body['key'] == null) return null;
    return RealEstateCategoryModel.fromJson(body);
  }

  //// Shared geo cascade (city -> locality), reused from registration ////

  /// Active cities for the form's first dropdown. The endpoint answers a
  /// bare array, not an envelope.
  Future<List<RealEstateGeoOption>> cities() async {
    final DioApiResponse response = await ApiRequestService.makeRequest(
      DairyPartnerEndpoints.registerCities,
      method: 'GET',
      token: await _auth.authToken(),
    );
    if (response.errorType != NetErrorType.none) _fail(response, 'GET cities');
    final String? raw = response.body;
    if (raw == null || raw.isEmpty) return const <RealEstateGeoOption>[];
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return const <RealEstateGeoOption>[];
      return decoded
          .whereType<Map>()
          .map(
            (Map m) =>
                RealEstateGeoOption.fromJson(Map<String, dynamic>.from(m)),
          )
          .toList();
    } on FormatException {
      return const <RealEstateGeoOption>[];
    }
  }

  /// Active localities within a city, for the second dropdown.
  Future<List<RealEstateGeoOption>> localities(String cityId) async {
    final DioApiResponse response = await ApiRequestService.makeRequest(
      RealEstateEndpoints.resolve(
        DairyPartnerEndpoints.localitiesFromCity,
        <String, String>{'city': cityId},
      ),
      method: 'GET',
      token: await _auth.authToken(),
    );
    if (response.errorType != NetErrorType.none) {
      _fail(response, 'GET localities');
    }
    final Map<String, dynamic> body = decodeBody(response);
    final List<dynamic> raw = body['localities'] is List
        ? body['localities'] as List<dynamic>
        : const <dynamic>[];
    return raw
        .whereType<Map>()
        .map(
          (Map m) => RealEstateGeoOption.fromJson(Map<String, dynamic>.from(m)),
        )
        .toList();
  }

  //// Media upload (bytes first, metadata after) ////

  /// Uploads one picked image and returns the stored `path` to send as a
  /// media `url`. The file endpoint answers `{ path }` (a storage key for
  /// cloud backends, a relative path for local ones) — see
  /// `resolveMediaUrl` where it is rendered.
  Future<String> uploadMediaImage(XFile file) async {
    final String filename = file.name.isNotEmpty
        ? file.name
        : file.path.split('/').last;
    final DioApiResponse response = await ApiRequestService.uploadFile(
      DairyPartnerEndpoints.uploadFile,
      filePath: file.path,
      filename: filename,
      token: await _auth.authToken(),
    );
    if (response.errorType != NetErrorType.none) {
      _fail(response, 'POST uploadImage');
    }
    final Map<String, dynamic> body = decodeBody(response);
    final String? path = body['path']?.toString();
    if (path == null || path.isEmpty) {
      throw RealEstateApiException(
        'Upload did not return a file path',
        response.statusCode,
      );
    }
    return path;
  }
}
