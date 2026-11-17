/*
 * WeWorkLocal
 * Hyperlocal Commerce & Service Platform
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

import 'dart:convert';

import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:partner/app/modules/stores/stores_endpoints.dart';

/// One failed stores call.
///
/// Carries the server's machine-readable code where it sent one — `CART_OUTLET_CONFLICT`
/// and `INSUFFICIENT_STOCK` are both actionable in the UI and must not be flattened into a
/// generic "something went wrong".
class StoresApiException implements Exception {
  StoresApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code;
  final int? statusCode;

  bool get isAuth => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

/// Builds the exception for a failed stores call, lifting the server's
/// machine-readable `code` (e.g. `CART_OUTLET_CONFLICT`) so the UI branches on codes
/// instead of string-matching messages.
StoresApiException _storesApiError(DioApiResponse response) {
  final dynamic payload = response.response?.data;
  String? message;
  String? code;
  if (payload is Map) {
    if (payload['message'] != null) message = payload['message'].toString();
    if (payload['code'] != null) code = payload['code'].toString();
  } else if (payload is String && payload.isNotEmpty) {
    try {
      final dynamic decoded = jsonDecode(payload);
      if (decoded is Map) {
        if (decoded['message'] != null) message = decoded['message'].toString();
        if (decoded['code'] != null) code = decoded['code'].toString();
      }
    } catch (_) {
      message = payload;
    }
  }
  return StoresApiException(
    message ?? 'Request failed (${response.statusCode ?? 'network'})',
    code: code,
    statusCode: response.statusCode,
  );
}

/// Partner-side reads and writes for the stores vertical.
///
/// Every call goes through [ApiRequestService] and takes the access token from
/// [AuthRepository], so a screen cannot accidentally issue an unauthenticated request.
///
/// ## BR-38 in one line
///
/// No method here accepts an outlet id for a data call. The outlet comes from the session,
/// so there is no argument a caller could tamper with to read another outlet's data. The
/// only place an outlet appears is `switchOutlet`, which is a REQUEST to change the session
/// property, validated server-side against the user's role scope.
class StoresPartnerRepository {
  StoresPartnerRepository({AuthRepository? auth})
    : _auth = auth ?? AuthRepository();

  final AuthRepository _auth;

  Future<Map<String, dynamic>> _call(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
   }) async {
    final List<ConnectivityResult> connectivity = await Connectivity().checkConnectivity();
    if (connectivity.isEmpty || connectivity.contains(ConnectivityResult.none)) {
      throw StoresApiException('No internet connection. Please check your network and try again.', statusCode: 0);
    }
    final DioApiResponse response = await ApiRequestService.makeRequest(
      path,
      method: method,
      body: body,
      token: await _auth.authToken(),
    );

    if (response.errorType == NetErrorType.none) {
      return decodeBody(response);
    }

    throw _storesApiError(response);
  }

  //// Session and scope ////

  /// Customer subscriptions for the active outlet (§6.18.10).
  Future<Map<String, dynamic>> customerSubscriptions({String? status, int page = 1, int limit = 20}) async {
    final StringBuffer path = StringBuffer(StoresPartnerEndpoints.subscriptions);
    final List<String> q = <String>['page=$page', 'limit=$limit'];
    if (status != null && status.isNotEmpty) q.add('status=${Uri.encodeQueryComponent(status)}');
    path.write('?${q.join('&')}');
    final Map<String, dynamic> body = await _call(path.toString());
    return body;
  }
  Future<Map<String, dynamic>> subscriptionDemand({int days = 7}) async {
    final StringBuffer path = StringBuffer(StoresPartnerEndpoints.subscriptionDemand);
    path.write('?days=$days');
    return _call(path.toString());
  }

  Future<Map<String, dynamic>> listRecurringPlans({String? status, int page = 1, int limit = 20}) async {
    final StringBuffer path = StringBuffer(StoresPartnerEndpoints.recurringPlans);
    final List<String> q = <String>['page=$page', 'limit=$limit'];
    if (status != null && status.isNotEmpty) q.add('status=${Uri.encodeQueryComponent(status)}');
    path.write('?${q.join('&')}');
    return _call(path.toString());
  }

  Future<Map<String, dynamic>> getRecurringPlan(String id) async {
    final String path = StoresPartnerEndpoints.recurringPlan.replaceAll('{plan}', id);
    return _call(path);
  }

  Future<Map<String, dynamic>> createRecurringPlan(Map<String, dynamic> body) async {
    return _call(StoresPartnerEndpoints.recurringPlans, method: 'POST', body: body);
  }

  Future<Map<String, dynamic>> updateRecurringPlan(String id, Map<String, dynamic> body) async {
    final String path = StoresPartnerEndpoints.recurringPlan.replaceAll('{plan}', id);
    return _call(path, method: 'PATCH', body: body);
  }

  Future<Map<String, dynamic>> transitionRecurringPlan(String id, String status) async {
    return _call(
      '${StoresPartnerEndpoints.recurringPlan.replaceAll('{plan}', id)}/$status',
      method: 'PATCH',
    );
  }

  Future<Map<String, dynamic>> listProducts() async {
    return _call(StoresPartnerEndpoints.catalogProducts);
  }

  Future<Map<String, dynamic>> listCategories() async {
    return _call(StoresPartnerEndpoints.catalogCategories);
  }

  Future<Map<String, dynamic>> exchanges({int page = 1, int limit = 20}) async {
    final StringBuffer path = StringBuffer(StoresPartnerEndpoints.exchangeList);
    path.write('?page=$page&limit=$limit');
    return _call(path.toString());
  }

  Future<Map<String, dynamic>> customers({int page = 1, int limit = 20}) async {
    final StringBuffer path = StringBuffer(StoresPartnerEndpoints.customers);
    path.write('?page=$page&limit=$limit');
    return _call(path.toString());
  }

  Future<List<Map<String, dynamic>>> myOutlets() async {
    final Map<String, dynamic> body = await _call(
      StoresPartnerEndpoints.myOutlets,
    );
    return _asList(body, 'outlets');
  }

  /// The permitted set without pinning an outlet — the outlet picker's own call.
  Future<Map<String, dynamic>> scope() => _call(StoresPartnerEndpoints.scope);

  /// One outlet's full detail, BY ID from the picker's list (not the active session).
  ///
  /// The id only makes sense as a value the server previously handed back — `myOutlets()`
  /// — so a screen cannot aim this at a foreign outlet and learn anything; the server
  /// re-checks the id against the caller's permitted set and 403s otherwise. This is what
  /// surfaces `deliveryConfig` (COD limits, minimum order), which the picker list omits.
  Future<Map<String, dynamic>> outletDetail(String outletId) => _call(
    storesResolve(StoresPartnerEndpoints.myOutlet, outlet: outletId),
  );

  /// Switches the active outlet. The server validates it against the role scope and 403s
  /// with OUT_OF_SCOPE if it is not permitted.
  Future<Map<String, dynamic>> switchOutlet(String outletId) => _call(
    StoresPartnerEndpoints.sessionOutlet,
    method: 'POST',
    body: <String, dynamic>{'outlet': outletId},
  );

  /// The BR-32 capability matrix. The app renders banners from this rather than
  /// re-implementing the matrix in Dart, so the two cannot drift apart.
  Future<Map<String, dynamic>> capabilities() =>
      _call(StoresPartnerEndpoints.capabilities);

  //// Dashboard ////

  Future<Map<String, dynamic>> dashboard() =>
      _call(StoresPartnerEndpoints.dashboard);

  Future<Map<String, dynamic>> chainAnalytics() =>
      _call(StoresPartnerEndpoints.chainAnalytics);

  Future<Map<String, dynamic>> listPolicies({int page = 1, int limit = 20}) async {
    return _call('${StoresPartnerEndpoints.policies}?page=$page&limit=$limit');
  }

  Future<Map<String, dynamic>> listReviews({int page = 1, int limit = 20}) async {
    return _call('${StoresPartnerEndpoints.reviews}?page=$page&limit=$limit');
  }

  Future<Map<String, dynamic>> deliveries({int page = 1, int limit = 20, String? status}) async {
    final List<String> q = <String>['page=$page', 'limit=$limit'];
    if (status != null && status.isNotEmpty) q.add('status=${Uri.encodeQueryComponent(status)}');
    return _call('${StoresPartnerEndpoints.deliveryPartnerList}?${q.join('&')}');
  }

  //// Orders ////

  Future<List<Map<String, dynamic>>> orders({
    int page = 1,
    int limit = 20,
    String? lifecycle,
  }) async {
    final Map<String, String> query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      'lifecycle': ?lifecycle,
    };
    final Map<String, dynamic> body = await _call(
      '${StoresPartnerEndpoints.orderList}?${_encode(query)}',
    );
    return _asList(body, 'orders');
  }

  Future<Map<String, dynamic>> order(String orderId) =>
      _call(storesResolve(StoresPartnerEndpoints.orderDetail, order: orderId));

  /// Manual order entry (§10.3.1, the counter-sale slice of F20).
  ///
  /// The request carries ONLY items, payment mode and display fields. Totals are
  /// recomputed server-side from the (variant × outlet) rows and the request's
  /// price/revenue fields are inert — what the server quotes is what the customer pays,
  /// never what a client typed. The kebab price the partner sees in the picker is the
  /// chain's indicative `variant.price`; the PLACE result carries the outlet truth.
  ///
  /// No method here takes an outlet: BR-38 — the outlet is the session's, like every
  /// other write. There is also no `customer` argument at this layer: the controller
  /// stamps the partner's own user id, so a counter sale never impersonates someone else.
  ///
  /// `addressSnapshot` is optional free text (counter pickup leaves it off); a
  /// delivery-type counter sale fills name/contact/line1 so a driver's app has somewhere
  /// to go. It is snapshot data, not a `UserAddress` reference — partners do not touch
  /// customers' saved addresses.
  Future<Map<String, dynamic>> createManualOrder({
    required List<Map<String, dynamic>> items,
    required String paymentMode,
    String? instructions,
    Map<String, dynamic>? addressSnapshot,
  }) => _call(
    StoresPartnerEndpoints.orderCreate,
    method: 'POST',
    body: <String, dynamic>{
      'items': items,
      'paymentMode': paymentMode,
      if (instructions != null && instructions.isNotEmpty)
        'instructions': instructions,
      'addressSnapshot': ?addressSnapshot,
    },
  );

  /// Lifecycle target is a PATH PARAMETER, matching the server's route. A client cannot
  /// invent a status: the transition table is the second gate.
  Future<Map<String, dynamic>> transitionOrder(String orderId, String status) =>
      _call(
        storesResolve(
          StoresPartnerEndpoints.orderTransition,
          order: orderId,
          status: status,
        ),
        method: 'PATCH',
      );

  Future<Map<String, dynamic>> cancelOrder(
    String orderId,
    String reason, {
    String reasonCode = 'out_of_stock',
  }) => _call(
    storesResolve(StoresPartnerEndpoints.orderCancel, order: orderId),
    method: 'POST',
    body: <String, dynamic>{'reason': reason, 'reasonCode': reasonCode},
  );

  Future<Map<String, dynamic>> rejectOrder(
    String orderId,
    String reason, {
    String reasonCode = 'cannot_fulfil',
  }) => _call(
    storesResolve(StoresPartnerEndpoints.orderReject, order: orderId),
    method: 'POST',
    body: <String, dynamic>{'reason': reason, 'reasonCode': reasonCode},
  );

  //// Picking ////

  Future<Map<String, dynamic>> pickList(String orderId) => _call(
    storesResolve(StoresPartnerEndpoints.orderPickList, order: orderId),
  );

  Future<Map<String, dynamic>> pickItem(
    String orderId,
    Map<String, dynamic> body,
  ) => _call(
    storesResolve(StoresPartnerEndpoints.orderPickItem, order: orderId),
    method: 'POST',
    body: body,
  );

  Future<Map<String, dynamic>> packing(
    String orderId,
    Map<String, dynamic> body,
  ) => _call(
    storesResolve(StoresPartnerEndpoints.orderPacking, order: orderId),
    method: 'POST',
    body: body,
  );

  Future<Map<String, dynamic>> fulfilmentSummary(String orderId) => _call(
    storesResolve(
      StoresPartnerEndpoints.orderFulfilmentSummary,
      order: orderId,
    ),
  );

  //// Delivery ////

  Future<List<Map<String, dynamic>>> availableDrivers() async {
    final Map<String, dynamic> body = await _call(
      StoresPartnerEndpoints.deliveryAvailableDrivers,
    );
    return _asList(body, 'drivers');
  }

  Future<Map<String, dynamic>> deliveryForOrder(String orderId) => _call(
    storesResolve(StoresPartnerEndpoints.deliveryByOrder, order: orderId),
  );

  Future<Map<String, dynamic>> assignDriver({
    required String orderId,
    required String driverId,
    num deliveryFee = 0,
    int estimatedMinutes = 30,
  }) => _call(
    StoresPartnerEndpoints.deliveryAssign,
    method: 'POST',
    body: <String, dynamic>{
      'order': orderId,
      'driver': driverId,
      'deliveryFee': deliveryFee,
      'estimatedMinutes': estimatedMinutes,
    },
  );

  //// Inventory ////

  Future<Map<String, dynamic>> stock({int page = 1, int limit = 20}) async =>
      _call('${StoresPartnerEndpoints.stockList}?page=$page&limit=$limit');

  Future<Map<String, dynamic>> lowStock() =>
      _call(StoresPartnerEndpoints.stockLow);

  /// Adjust stock for ONE variant.
  ///
  /// `variant` and `product` are REQUIRED: the controller spreads the request body straight
  /// into `adjustStock`, and the service resolves the stock row by `(outlet, variant)`.
  /// `outlet`, `chain` and the actor are injected server-side from the token, which is why
  /// BR-38 holds even though the caller picks a variant freely.
  ///
  /// `type` must be one of the server's five movement types — it rejects anything else with
  /// `Unknown movement type`, so the caller sends the server's vocabulary rather than its own.
  Future<Map<String, dynamic>> adjustStock({
    required String variant,
    required String product,
    required String type,
    required int quantity,
    required String reason,
  }) => _call(
    StoresPartnerEndpoints.stockAdjust,
    method: 'POST',
    body: <String, dynamic>{
      'variant': variant,
      'product': product,
      'type': type,
      'quantity': quantity,
      'reason': reason,
    },
  );

  //// Catalogue ////

  Future<Map<String, dynamic>> catalogueProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) async {
    final Map<String, String> query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
    };
    return _call('${StoresPartnerEndpoints.catalogProducts}?${_encode(query)}');
  }

  Future<Map<String, dynamic>> catalogueProduct(String productId) => _call(
    storesResolve(StoresPartnerEndpoints.catalogProduct, product: productId),
  );

  Future<List<Map<String, dynamic>>> categories() async {
    final Map<String, dynamic> body = await _call(
      StoresPartnerEndpoints.catalogCategories,
    );
    return _asList(body, 'categories');
  }

  Future<List<Map<String, dynamic>>> subcategories({String? category}) async {
    final String suffix = category == null || category.isEmpty
        ? ''
        : '?category=${Uri.encodeQueryComponent(category)}';
    final Map<String, dynamic> body = await _call(
      '${StoresPartnerEndpoints.catalogSubcategories}$suffix',
    );
    return _asList(body, 'subcategories');
  }

  Future<List<Map<String, dynamic>>> brands({String? search}) async {
    final String suffix = search == null || search.trim().isEmpty
        ? ''
        : '?search=${Uri.encodeQueryComponent(search.trim())}';
    final Map<String, dynamic> body = await _call(
      '${StoresPartnerEndpoints.catalogBrands}$suffix',
    );
    return _asList(body, 'brands');
  }

  /// Uploads a product CSV/XLSX. The server validates the whole file before
  /// writing, and creates pending brand requests for unknown brand names.
  Future<Map<String, dynamic>> importProducts({
    required String filePath,
    required String filename,
  }) async {
    final DioApiResponse response = await ApiRequestService.uploadFile(
      StoresPartnerEndpoints.catalogProductsImport,
      filePath: filePath,
      filename: filename,
      field: 'file',
      token: await _auth.authToken(),
    );

    if (response.errorType == NetErrorType.none) {
      return decodeBody(response);
    }

    throw _storesApiError(response);
  }

  Future<Map<String, dynamic>> requestBrand({
    required String name,
    String? category,
    String? subcategory,
    String? note,
  }) {
    final Map<String, dynamic> body = <String, dynamic>{'name': name};
    if (category != null) body['category'] = category;
    if (subcategory != null) body['subcategory'] = subcategory;
    if (note != null && note.isNotEmpty) body['note'] = note;

    return _call(
      StoresPartnerEndpoints.catalogBrandRequest,
      method: 'POST',
      body: body,
    );
  }

  Future<Map<String, dynamic>> brandRequests({String status = 'all'}) =>
      _call(
        '${StoresPartnerEndpoints.catalogBrandRequests}?status=$status',
      );

  Future<Map<String, dynamic>> submitBrandCertification(
    String brandId,
    Map<String, dynamic> body,
  ) => _call(
    storesResolve(
      StoresPartnerEndpoints.catalogBrandCertification,
      brand: brandId,
    ),
    method: 'POST',
    body: body,
  );

  Future<Map<String, dynamic>> createProduct(Map<String, dynamic> body) =>
      _call(StoresPartnerEndpoints.catalogProducts, method: 'POST', body: body);

  Future<Map<String, dynamic>> updateProduct(
    String productId,
    Map<String, dynamic> body,
  ) => _call(
    storesResolve(StoresPartnerEndpoints.catalogProduct, product: productId),
    method: 'PATCH',
    body: body,
  );

  /// Archive (BR-25). The endpoint is DELETE, but the server only stamps the archive
  /// fields; order lines keep resolving.
  Future<Map<String, dynamic>> archiveProduct(String productId) => _call(
    storesResolve(StoresPartnerEndpoints.catalogProduct, product: productId),
    method: 'DELETE',
  );

  /// BR-11 — the form is generated from attribute templates, so the app renders whatever
  /// the category needs instead of hardcoding a clothing form.
  Future<Map<String, dynamic>> productForm({
    String? category,
    String? subcategory,
  }) {
    final Map<String, String> query = <String, String>{
      'category': ?category,
      'subcategory': ?subcategory,
    };
    final String suffix = query.isEmpty ? '' : '?${_encode(query)}';
    return _call('${StoresPartnerEndpoints.productForm}$suffix');
  }

  Future<Map<String, dynamic>> generateVariants(
    String productId,
    Map<String, dynamic> body,
  ) => _call(
    storesResolve(StoresPartnerEndpoints.generateVariants, product: productId),
    method: 'POST',
    body: body,
  );

  //// Fleet (BR-06/07: add and deactivate; never hard-delete) ////

  Future<Map<String, dynamic>> drivers({int page = 1, int limit = 20}) async =>
      _call('${StoresPartnerEndpoints.driverList}?page=$page&limit=$limit');

  Future<Map<String, dynamic>> suspendDriver(String driverId, String reason) =>
      _call(
        storesResolve(StoresPartnerEndpoints.driverSuspend, driver: driverId),
        method: 'POST',
        body: <String, dynamic>{'reason': reason},
      );

  Future<Map<String, dynamic>> reactivateDriver(String driverId) => _call(
    storesResolve(StoresPartnerEndpoints.driverReactivate, driver: driverId),
    method: 'POST',
    body: <String, dynamic>{},
  );

  //// Post-sale, money ////

  Future<Map<String, dynamic>> returns({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final Map<String, String> query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      'status': ?status,
    };
    return _call('${StoresPartnerEndpoints.returnList}?${_encode(query)}');
  }

  Future<Map<String, dynamic>> returnStatus(String returnId, String status) =>
      _call(
        storesResolve(
          StoresPartnerEndpoints.returnStatus,
          returnId: returnId,
          status: status,
        ),
        method: 'PATCH',
      );

  Future<Map<String, dynamic>> settlements({
    int page = 1,
    int limit = 20,
    String? status,
    String? period,
  }) async {
    final Map<String, String> query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      'status': ?status,
      'period': ?period,
    };
    return _call('${StoresPartnerEndpoints.settlementList}?${_encode(query)}');
  }

  Future<Map<String, dynamic>> settlement(String settlementId) => _call(
    storesResolve(
      StoresPartnerEndpoints.settlementDetail,
      settlement: settlementId,
    ),
  );

  /// The chain's current subscription (`GET /subscription`), or null when there is none.
  /// Exactly-once per chain by the partial unique index — a chain carries one live row
  /// plus history, never two live rows.
  Future<Map<String, dynamic>?> currentSubscription() async {
    final Map<String, dynamic> body = await _call(
      StoresPartnerEndpoints.subscriptionCurrent,
    );
    final dynamic s = body['subscription'];
    return s is Map<String, dynamic> ? s : null;
  }

  /// Starts a gateway payment for the chain subscription (BR-16).
  /// Returns the PaymentInitiation to complete in the gateway, not a paid flag.
  Future<Map<String, dynamic>> paySubscription(String subscriptionId) => _call(
    StoresPartnerEndpoints.subscriptionPay,
    method: 'POST',
    body: <String, dynamic>{'subscription': subscriptionId},
  );

  /// Moves the subscription to a new status. The target is a path parameter and the
  /// service transition table is the gate.
  Future<Map<String, dynamic>> transitionSubscription(
    String subscriptionId,
    String status,
  ) => _call(
    storesResolve(
      StoresPartnerEndpoints.subscriptionTransition,
      subscription: subscriptionId,
      status: status,
    ),
    method: 'PATCH',
  );

  /// BR-21: warranty claims. Read by status ladder; transitions are path params gated
  /// server-side (`WARRANTY_TRANSITIONS`).
  Future<Map<String, dynamic>> warranties({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final Map<String, String> query = <String, String>{
      'page': '$page',
      'limit': '$limit',
      'status': ?status,
    };
    return _call('${StoresPartnerEndpoints.warrantyList}?${_encode(query)}');
  }

  Future<Map<String, dynamic>> transitionWarranty(
    String warrantyId,
    String status,
  ) => _call(
    storesResolve(
      StoresPartnerEndpoints.warrantyStatus,
      warranty: warrantyId,
      status: status,
    ),
    method: 'PATCH',
  );

  Future<List<Map<String, dynamic>>> promotions() async {
    final Map<String, dynamic> body = await _call(
      StoresPartnerEndpoints.promotionList,
    );
    return _asList(body, 'promotions');
  }

  Future<List<Map<String, dynamic>>> coupons() async {
    final Map<String, dynamic> body = await _call(
      StoresPartnerEndpoints.couponList,
    );
    return _asList(body, 'coupons');
  }

  Future<Map<String, dynamic>> createCoupon(Map<String, dynamic> body) =>
      _call(StoresPartnerEndpoints.couponCreate, method: 'POST', body: body);

  /// Creates a promotion. Required by the server: `name`, `type`, `value`, `startsAt`,
  /// `endsAt`; a `percent_off` also needs `maxDiscount`. `type` is the closed set in
  /// `promotionCreateValidation`. The server returns a draft pending approval.
  Future<Map<String, dynamic>> createPromotion(Map<String, dynamic> body) =>
      _call(StoresPartnerEndpoints.promotionCreate, method: 'POST', body: body);

  Future<Map<String, dynamic>> pausePromotion(String promotionId) => _call(
    storesResolve(
      StoresPartnerEndpoints.promotionPause,
      promotion: promotionId,
    ),
    method: 'POST',
  );

  Future<Map<String, dynamic>> resumePromotion(String promotionId) => _call(
    storesResolve(
      StoresPartnerEndpoints.promotionResume,
      promotion: promotionId,
    ),
    method: 'POST',
  );

  /// Tests whether a code applies to a cart amount and what it discounts.
  /// Partners test before printing a code, not after a customer complains.
  Future<Map<String, dynamic>> validatePromotion(String code, num cartAmount) =>
      _call(
        StoresPartnerEndpoints.promotionValidate,
        method: 'POST',
        body: <String, dynamic>{
          'code': code.toUpperCase(),
          'cartAmount': cartAmount,
        },
      );

  Future<Map<String, dynamic>> complaints() =>
      _call(StoresPartnerEndpoints.complaintList);

  /// Moves a complaint. Status is a path parameter; the server gates the transition
  /// (`ILLEGAL_COMPLAINT_MOVE` on anything outside the table).
  Future<Map<String, dynamic>> transitionComplaint(
    String complaintId,
    String status,
  ) => _call(
    storesResolve(
      StoresPartnerEndpoints.complaintStatus,
      complaint: complaintId,
      status: status,
    ),
    method: 'PATCH',
  );

  //// Featured placements and the team (BR-40) ////

  Future<Map<String, dynamic>> featured({int page = 1, int limit = 20}) async =>
      _call('${StoresPartnerEndpoints.featuredList}?page=$page&limit=$limit');

  Future<Map<String, dynamic>> featuredPending() =>
      _call(StoresPartnerEndpoints.featuredPending);

  Future<Map<String, dynamic>> approveFeatured(String placementId) => _call(
    storesResolve(
      StoresPartnerEndpoints.featuredApprove,
      placement: placementId,
    ),
    method: 'POST',
    body: <String, dynamic>{},
  );

  Future<Map<String, dynamic>> rejectFeatured(
    String placementId,
    String reason,
  ) => _call(
    storesResolve(
      StoresPartnerEndpoints.featuredReject,
      placement: placementId,
    ),
    method: 'POST',
    body: <String, dynamic>{'reason': reason},
  );

  /// BR-40: role assignment is a model. This is the roster — who holds what role at
  /// which scope — not a user list.
  Future<Map<String, dynamic>> team() => _call(StoresPartnerEndpoints.team);

  //// Onboarding — one step key per save ////

  /// The draft, with the server-computed `currentStep`, `completedSteps` and
  /// `incompleteSteps`. The wizard must render progress from these fields.
  Future<Map<String, dynamic>> application() =>
      _call(StoresPartnerEndpoints.application);

  /// Saves ONE step (e.g. `{'businessInfo': {...}}`). The server shallow-merges
  /// it into the draft without wiping the other steps — except `documents`, which
  /// is an array and is REPLACED, so the caller must send the full document list.
  Future<Map<String, dynamic>> saveApplicationStep(
    Map<String, dynamic> patch,
  ) => _call(StoresPartnerEndpoints.application, method: 'PATCH', body: patch);

  /// Submits. Refused with 422 while `incompleteSteps` is non-empty; the server
  /// says exactly what is missing.
  Future<Map<String, dynamic>> submitApplication() => _call(
    StoresPartnerEndpoints.applicationSubmit,
    method: 'POST',
    body: <String, dynamic>{},
  );

  static String _encode(Map<String, String> query) => query.entries
      .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
      .join('&');

  /// The stores APIs return either a bare list or a paged envelope depending on the
  /// endpoint, so normalise to a list rather than making every screen handle both.
  static List<Map<String, dynamic>> _asList(
    Map<String, dynamic> body,
    String key,
  ) {
    final dynamic direct = body[key];
    if (direct is List) {
      return direct.whereType<Map<String, dynamic>>().toList();
    }
    final dynamic items = body['items'];
    if (items is List) {
      return items.whereType<Map<String, dynamic>>().toList();
    }
    final dynamic results = body['results'];
    if (results is List) {
      return results.whereType<Map<String, dynamic>>().toList();
    }
    return <Map<String, dynamic>>[];
  }
}

/// The store-driver surface.
///
/// BR-05: store drivers are the outlet's own. They appear in this Partner app and never in
/// `Deliveryman_app`, which is the LocalWala platform fleet.
class StoresDriverRepository {
  StoresDriverRepository({AuthRepository? auth})
    : _auth = auth ?? AuthRepository();

  final AuthRepository _auth;

  Future<Map<String, dynamic>> _call(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final DioApiResponse response = await ApiRequestService.makeRequest(
      path,
      method: method,
      body: body,
      token: await _auth.authToken(),
    );
    if (response.errorType == NetErrorType.none) {
      return decodeBody(response);
    }
    throw _storesApiError(response);
  }

  Future<Map<String, dynamic>> deliveries() =>
      _call(StoresDriverEndpoints.deliveryList);

  Future<Map<String, dynamic>> delivery(String deliveryId) => _call(
    storesResolve(StoresDriverEndpoints.deliveryDetail, delivery: deliveryId),
  );

  Future<Map<String, dynamic>> deliveryOrder(String deliveryId) => _call(
    storesResolve(StoresDriverEndpoints.deliveryOrder, delivery: deliveryId),
  );

  Future<Map<String, dynamic>> transition(String deliveryId, String status) =>
      _call(
        storesResolve(
          StoresDriverEndpoints.deliveryStatus,
          delivery: deliveryId,
          status: status,
        ),
        method: 'POST',
      );

  /// BR-29 — the handover cannot complete without the customer's OTP. The app must not
  /// offer a "mark delivered" affordance that skips this call.
  Future<Map<String, dynamic>> verifyOtp(String deliveryId, String otp) =>
      _call(
        storesResolve(
          StoresDriverEndpoints.deliveryVerifyOtp,
          delivery: deliveryId,
        ),
        method: 'POST',
        body: <String, dynamic>{'otp': otp},
      );

  Future<Map<String, dynamic>> fail(String deliveryId, String reason) => _call(
    storesResolve(StoresDriverEndpoints.deliveryFail, delivery: deliveryId),
    method: 'POST',
    body: <String, dynamic>{'reason': reason},
  );

  Future<Map<String, dynamic>> earnings() =>
      _call(StoresDriverEndpoints.earnings);
}
