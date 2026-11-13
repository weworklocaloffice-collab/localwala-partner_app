import 'dart:convert';

import 'package:partner/app/core/config/api_endpoints.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/config/payment_endpoints.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';

/// Partner-side calls and the public outlet summary used in the Partner profile.
/// Authenticated partner endpoints are guarded server side by the `dairyPartner`
/// rights added to `API/src/config/roles.js`.
///
/// ## Path placeholders
///
/// Partner routes carry the outlet in the **path**, as `{id}` â€” not in a body or
/// query string, which is what this repository used to send. Every method therefore
/// goes through [_path], which substitutes the outlet plus whatever entity id the
/// endpoint declares. A missing value throws from
/// [DairyPartnerEndpoints.resolve] rather than issuing a request to a URL
/// containing a literal `{id}`, which would fail as an opaque 404.
///
/// Endpoints marked "not built yet" in `api_endpoints.dart` have no server route.
/// Their methods still resolve and still issue the request; they fail with a
/// server 404, which is the honest signal that the screen is ahead of the API.
/// ## No outlet in the path
///
/// Partner endpoints carry **no outlet id**. The server derives the outlet from
/// the access token, so there is nothing here to send and nothing a client could
/// change to reach another outlet. Paths still declare resource ids â€” `{id}` for a
/// product, SKU or provider, `{run}`, `{order}`, `{can}` â€” and those are supplied by
/// the caller.
class PartnerRepository {
  PartnerRepository({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  final AuthRepository _authRepository;

  /// Fills an endpoint template's resource placeholders.
  Future<String> _path(
    String template, [
    Map<String, String> values = const <String, String>{},
  ]) async {
    return DairyPartnerEndpoints.resolve(template, values);
  }

  String _withQuery(String endpoint, Map<String, String> query) {
    if (query.isEmpty) return endpoint;
    return '$endpoint?${Uri(queryParameters: query).query}';
  }

  //// Dashboard ////

  /// Public storefront-safe business details used by the Partner profile.
  Future<DioApiResponse> businessProfile(String businessId) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.businessProfile,
        <String, String>{'id': businessId},
      ),
      method: 'GET',
    );
  }

  Future<DioApiResponse> dashboard({String period = '7d'}) async {
    final String endpoint = await _path(DairyPartnerEndpoints.partnerDashboard);
    return ApiRequestService.makeRequest(
      _withQuery(endpoint, <String, String>{'period': period}),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> dairyOutlets() async => ApiRequestService.makeRequest(
    await _path(DairyPartnerEndpoints.partnerOutlets),
    method: 'GET',
    token: await _authRepository.authToken(),
  );

  Future<DioApiResponse> selectDairyOutlet(String businessId) async => ApiRequestService.makeRequest(
    await _path(DairyPartnerEndpoints.partnerOutletSelect),
    method: 'POST',
    token: await _authRepository.authToken(),
    body: <String, dynamic>{'business': businessId},
  );

  Future<DioApiResponse> dairySalesReport({String? from, String? to}) async {
    final Map<String, String> query = <String, String>{
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    };
    return ApiRequestService.makeRequest(
      _withQuery(await _path(DairyPartnerEndpoints.partnerSalesReport), query),
      method: 'GET', token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> dairySalesCsv({required String from, required String to}) async =>
      ApiRequestService.makeRequest(
        _withQuery(await _path(DairyPartnerEndpoints.partnerSalesExport), <String, String>{'from': from, 'to': to}),
        method: 'GET', token: await _authRepository.authToken(),
      );

  Future<DioApiResponse> supportTickets() async => ApiRequestService.makeRequest(
    _withQuery(await _path(DairyPartnerEndpoints.partnerSupportTickets), const <String, String>{'limit': '50'}),
    method: 'GET', token: await _authRepository.authToken(),
  );

  Future<DioApiResponse> createSupportTicket(Map<String, dynamic> body) async => ApiRequestService.makeRequest(
    await _path(DairyPartnerEndpoints.partnerSupportTickets),
    method: 'POST', token: await _authRepository.authToken(), body: body,
  );

  Future<DioApiResponse> replySupportTicket(String ticketId, String message) async => ApiRequestService.makeRequest(
    await _path(DairyPartnerEndpoints.partnerSupportReplies, <String, String>{'ticket': ticketId}),
    method: 'POST', token: await _authRepository.authToken(), body: <String, dynamic>{'message': message},
  );

  Future<DioApiResponse> supportChatList() async => ApiRequestService.makeRequest(
    await _path(DairyPartnerEndpoints.partnerSupportChat),
    method: 'GET', token: await _authRepository.authToken(),
  );

  Future<DioApiResponse> createSupportChat() async => ApiRequestService.makeRequest(
    await _path(DairyPartnerEndpoints.partnerSupportChat),
    method: 'POST', token: await _authRepository.authToken(),
  );

  Future<DioApiResponse> supportChatMessages(String roomId) async => ApiRequestService.makeRequest(
    await _path(DairyPartnerEndpoints.partnerSupportChatMessages, <String, String>{'room': roomId}),
    method: 'GET', token: await _authRepository.authToken(),
  );

  Future<DioApiResponse> sendSupportChatMessage(String roomId, String message) async => ApiRequestService.makeRequest(
    await _path(DairyPartnerEndpoints.partnerSupportChatMessages, <String, String>{'room': roomId}),
    method: 'POST', token: await _authRepository.authToken(), body: <String, dynamic>{'message': message},
  );

  Future<DioApiResponse> requestSupportChatHandover(String roomId) async => ApiRequestService.makeRequest(
    await _path(DairyPartnerEndpoints.partnerSupportChatHandover, <String, String>{'room': roomId}),
    method: 'POST', token: await _authRepository.authToken(),
  );

  Future<DioApiResponse> partnerBusinessProfile() async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerBusinessProfile),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> payFranchiseJoiningFee() async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerFranchiseJoiningFeePay),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: const <String, dynamic>{},
    );
  }

  Future<DioApiResponse> updatePartnerOutletLocation({
    required String address,
    required double longitude,
    required double latitude,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerBusinessProfile),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'address': address,
        'coordinates': <double>[longitude, latitude],
      },
    );
  }

  Future<DioApiResponse> coverage() async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerCoverage),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> availability() async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerAvailability),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> updateAvailability(Map<String, dynamic> settings) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerAvailability),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: settings,
    );
  }

  Future<DioApiResponse> requestCoverage({
    required List<String> localityIds,
    String message = '',
  }) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerCoverageRequests),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'localityIds': localityIds,
        'message': message.trim(),
      },
    );
  }

  //// Dairy marketing ////

  Future<DioApiResponse> marketingPackages() async {
    return ApiRequestService.makeRequest(
      _withQuery(await _path(DairyPartnerEndpoints.partnerMarketingPackages),
          const <String, String>{'limit': '100'}),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> marketingCampaigns() async {
    return ApiRequestService.makeRequest(
      _withQuery(await _path(DairyPartnerEndpoints.partnerMarketingCampaigns),
          const <String, String>{'limit': '100'}),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> createMarketingCampaign(
    Map<String, dynamic> campaign,
  ) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerMarketingCampaigns),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: campaign,
    );
  }

  Future<DioApiResponse> marketingCoupons() async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerMarketingCoupons),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> createMarketingCoupon(Map<String, dynamic> coupon) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerMarketingCoupons),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: coupon,
    );
  }

  Future<DioApiResponse> disableMarketingCoupon(String couponId) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.partnerMarketingCouponDisable,
        <String, String>{'coupon': couponId},
      ),
      method: 'PATCH',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> marketingCouponReport(
    String couponId, {
    required DateTime from,
    required DateTime to,
  }) async {
    final String path = await _path(
      DairyPartnerEndpoints.partnerMarketingCouponReport,
      <String, String>{'coupon': couponId},
    );
    return ApiRequestService.makeRequest(
      _withQuery(path, <String, String>{
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      }),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> payMarketingCampaign(String campaignId) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.partnerMarketingCampaignPay,
        <String, String>{'campaign': campaignId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: const <String, dynamic>{},
    );
  }

  Future<DioApiResponse> marketingPaymentOrder(String payLink) async {
    return _paymentOrder(payLink);
  }

  Future<DioApiResponse> franchiseJoiningFeePaymentOrder(String payLink) async {
    return _paymentOrder(payLink);
  }

  Future<DioApiResponse> _paymentOrder(String payLink) async {
    return ApiRequestService.makeRequest(
      PaymentEndpoints.resolve(
        PaymentEndpoints.makePayment,
        <String, String>{'id': payLink},
      ),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> verifyMarketingPayment(
    String payLink, {
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    return _verifyPayment(
      payLink,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
    );
  }

  Future<DioApiResponse> verifyFranchiseJoiningFeePayment(
    String payLink, {
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    return _verifyPayment(
      payLink,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
    );
  }

  Future<DioApiResponse> _verifyPayment(
    String payLink, {
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    return ApiRequestService.makeRequest(
      PaymentEndpoints.resolve(
        PaymentEndpoints.verifyPayment,
        <String, String>{'id': payLink},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'razorpay_payment_id': paymentId,
        'razorpay_order_id': orderId,
        'razorpay_signature': signature,
      },
    );
  }

  //// Catalogue ////

  Future<DioApiResponse> products({
    int page = 1,
    int limit = ApiRequestService.pageSize,
  }) async {
    final String endpoint = await _path(DairyPartnerEndpoints.partnerProducts);
    return ApiRequestService.makeRequest(
      _withQuery(endpoint, <String, String>{
        'page': '$page',
        'limit': '$limit',
      }),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Platform-managed dairy taxonomy. Partners may select these values but
  /// cannot create or change them.
  Future<DioApiResponse> dairyCategories() async {
    return ApiRequestService.makeRequest(
      _withQuery(await _path(DairyPartnerEndpoints.dairyCategories), const <String, String>{
        'page': '1',
        'limit': '100',
      }),
      method: 'GET',
    );
  }

  Future<DioApiResponse> dairySubCategories(String categoryId) async {
    return ApiRequestService.makeRequest(
      _withQuery(await _path(DairyPartnerEndpoints.dairySubCategories), <String, String>{
        'category': categoryId,
        'page': '1',
        'limit': '100',
      }),
      method: 'GET',
    );
  }

  Future<DioApiResponse> dairyBrands() async {
    return ApiRequestService.makeRequest(
      _withQuery(await _path(DairyPartnerEndpoints.dairyBrands), const <String, String>{
        'page': '1',
        'limit': '100',
      }),
      method: 'GET',
    );
  }

  Future<DioApiResponse> createProduct(Map<String, dynamic> product) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerProductCreate),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: product,
    );
  }

  Future<DioApiResponse> createSku(Map<String, dynamic> sku) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerSkuCreate),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: sku,
    );
  }

  /// Uploads one product image through the shared authenticated media endpoint.
  /// The returned `path` is stored in the product's `images` array.
  Future<DioApiResponse> uploadProductImage({
    required String filePath,
    required String filename,
  }) async {
    return ApiRequestService.uploadFile(
      DairyPartnerEndpoints.uploadFile,
      filePath: filePath,
      filename: filename,
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> updateProduct(
    String productId,
    Map<String, dynamic> changes,
  ) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.partnerProductUpdate,
        <String, String>{'id': productId},
      ),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: changes,
    );
  }

  Future<DioApiResponse> deleteProduct(String productId) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.partnerProductDelete,
        <String, String>{'id': productId},
      ),
      method: 'DELETE',
      token: await _authRepository.authToken(),
    );
  }

  //// Inventory ////

  Future<DioApiResponse> inventory({
    int page = 1,
    int limit = ApiRequestService.pageSize,
  }) async {
    final String endpoint = await _path(DairyPartnerEndpoints.partnerInventoryList);
    return ApiRequestService.makeRequest(
      _withQuery(endpoint, <String, String>{'page': '$page', 'limit': '$limit'}),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> updateStock(String skuId, int delta) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.partnerInventoryUpdate,
        <String, String>{'id': skuId},
      ),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'delta': delta},
    );
  }

  Future<DioApiResponse> inventoryLots(String skuId) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerSkuLots, <String, String>{'id': skuId}),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> inventoryMovements({String? skuId, String? lotId, int page = 1, int limit = 50}) async {
    final String endpoint = await _path(DairyPartnerEndpoints.partnerInventoryMovements);
    final Map<String, String> query = <String, String>{'page': '$page', 'limit': '$limit'};
    if (skuId != null && skuId.isNotEmpty) query['sku'] = skuId;
    if (lotId != null && lotId.isNotEmpty) query['lot'] = lotId;
    return ApiRequestService.makeRequest(
      _withQuery(endpoint, query),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> inventoryReport() async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerInventoryReport),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> writeOffInventoryLot(String skuId, String lotId, {
    required int quantity,
    required String bucket,
    required String reason,
    String? note,
  }) async {
    final String endpoint = await _path(DairyPartnerEndpoints.partnerSkuLotWriteOff,
        <String, String>{'id': skuId, 'lot': lotId});
    return ApiRequestService.makeRequest(
      endpoint,
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'quantity': quantity,
        'bucket': bucket,
        'reason': reason,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
  }

  Future<DioApiResponse> setInventoryLotDisposition(String skuId, String lotId, {
    required String action,
    required String reason,
  }) async {
    final String endpoint = await _path(DairyPartnerEndpoints.partnerSkuLotDisposition,
        <String, String>{'id': skuId, 'lot': lotId});
    return ApiRequestService.makeRequest(
      endpoint,
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'action': action, 'reason': reason},
    );
  }

  Future<DioApiResponse> receiveInventoryLot(
    String skuId, {
    required String lotNo,
    required int quantity,
    required DateTime expiry,
    String? notes,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerSkuLots, <String, String>{'id': skuId}),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'lotNo': lotNo,
        'quantity': quantity,
        'expiry': expiry.toIso8601String(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      },
    );
  }

  Future<DioApiResponse> updateSku(String skuId, Map<String, dynamic> changes) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerSkuUpdate, <String, String>{'id': skuId}),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: changes,
    );
  }

  //// Orders ////

  Future<DioApiResponse> orders({
    int page = 1,
    int limit = ApiRequestService.pageSize,
    String? status,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerOrderList),
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      },
    );
  }

  Future<DioApiResponse> orderSummary() async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerOrderSummary),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Accept, reject or ready a single order.
  ///
  /// The API models these as one status route rather than three verbs, so the
  /// action maps onto a status segment.
  Future<DioApiResponse> orderAction(String orderId, String action) async {
    final String endpoint = switch (action) {
      'accept' => DairyPartnerEndpoints.partnerOrderAccept,
      'reject' => DairyPartnerEndpoints.partnerOrderReject,
      'ready' => DairyPartnerEndpoints.partnerOrderReady,
      _ => throw ArgumentError('Unknown order action: $action'),
    };
    return ApiRequestService.makeRequest(
      await _path(endpoint, <String, String>{'order': orderId}),
      method: 'PATCH',
      token: await _authRepository.authToken(),
    );
  }

  /// Hand a confirmed order to the delivery run.
  Future<DioApiResponse> dispatchOrder(
    String orderId, {
    String? slotId,
    String? agentId,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.partnerOrderDispatch,
        <String, String>{'order': orderId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        if (slotId != null) 'slot': slotId,
        if (agentId != null) 'agent': agentId,
      },
    );
  }

  //// Subscriptions ////

  Future<DioApiResponse> subscriptions({
    int page = 1,
    int limit = ApiRequestService.pageSize,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerSubscriptionList),
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'page': page, 'limit': limit},
    );
  }

  Future<DioApiResponse> subscriptionAction(
    String subscriptionId,
    String action,
  ) async {
    final String endpoint = action == 'pause'
        ? DairyPartnerEndpoints.partnerSubscriptionPause
        : DairyPartnerEndpoints.partnerSubscriptionResume;
    return ApiRequestService.makeRequest(
      await _path(endpoint, <String, String>{'subscription': subscriptionId}),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      // A pause must end. The API requires `to`, matching the customer route and
      // the model: "paused until further notice" is a cancellation, not a pause.
      body: action == 'pause'
          ? <String, dynamic>{
              'to': DateTime.now()
                  .add(const Duration(days: 7))
                  .toUtc()
                  .toIso8601String(),
              'reason': 'Paused from the partner app',
            }
          : <String, dynamic>{},
    );
  }

  //// Customers ////

  Future<DioApiResponse> customers({
    int page = 1,
    int limit = ApiRequestService.pageSize,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerCustomerList),
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'page': page, 'limit': limit},
    );
  }

  //// Own fleet ////

  Future<DioApiResponse> drivers({
    int page = 1,
    int limit = ApiRequestService.pageSize,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerDriverList),
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'page': page, 'limit': limit},
    );
  }

  Future<DioApiResponse> inviteDriver(int mobile, String countryCode) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerDriverInvite),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'mobile': mobile, 'countryCode': countryCode},
    );
  }

  /// Creates the driver's fleet profile. The driver activates login with OTP
  /// and chooses a password independently; the partner never sets credentials.
  Future<DioApiResponse> createDriverAccount(Map<String, dynamic> details) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerDriverCreate),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{...details, 'countryCode': details['countryCode'] ?? '+91'},
    );
  }

  Future<DioApiResponse> reissueDriverActivation(String inviteId) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.partnerDriverActivationReissue,
        <String, String>{'invite': inviteId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }

  /// Approves or blocks a rider on this outlet's fleet.
///
/// The body key is `approve`, not `status`: `DairyDriver.status` is the profile's
/// own validity and setting it from a partner's tap would make "blocked" and
/// "deleted" indistinguishable on the record.
Future<DioApiResponse> approveDriver(
  String driverId,
  bool approve, {
  String? reason,
}) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.partnerDriverApprove,
        <String, String>{'id': driverId},
      ),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'approve': approve,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
  }

  /// Detaches a rider from this fleet. Their history is kept.
  Future<DioApiResponse> removeDriver(String driverId, {String? reason}) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.partnerDriverRemove,
        <String, String>{'id': driverId},
      ),
      method: 'DELETE',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{if (reason != null) 'reason': reason},
    );
  }

  Future<DioApiResponse> driverInvites() async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerDriverInvites),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> revokeDriverInvite(String inviteId, {String? reason}) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.partnerDriverInviteRevoke,
        <String, String>{'invite': inviteId},
      ),
      method: 'DELETE',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{if (reason != null) 'reason': reason},
    );
  }

  /// Pays a rider from the outlet's wallet.
  ///
  /// One payout, one rider - so `driverPayout` takes the rider id in its path
  /// rather than being a list endpoint. There is no payout history endpoint yet;
  /// `payoutHistory` rides along on the rider row.
  Future<DioApiResponse> driverPayout(
    String driverId,
    double amount, {
    String? reference,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.partnerDriverPayout,
        <String, String>{'id': driverId},
      ),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'amount': amount,
        if (reference != null) 'reference': reference,
      },
    );
  }

  //// Notifications ////

/// The signed-in account's notices.
///
/// No user id is sent: the server reads the reader from the token, so there is
/// no parameter here that could show someone else's list.
Future<DioApiResponse> notifications({bool unreadOnly = false}) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.notificationList),
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        if (unreadOnly) 'unreadOnly': true,
        'limit': ApiRequestService.perPageLimit,
      },
    );
  }

  /// Marks notices read - all of them, or the named ones.
  Future<DioApiResponse> markNotificationsRead({List<String>? ids}) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.markAllRead),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{if (ids != null) 'ids': ids},
    );
  }

  /// Hides one notice from the list. The row is kept server-side for audit.
  Future<DioApiResponse> dismissNotification(String notificationId) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.dismissNotification,
        <String, String>{'id': notificationId},
      ),
      method: 'DELETE',
      token: await _authRepository.authToken(),
    );
  }

  //// Runs ////

  Future<DioApiResponse> runs({
    int page = 1,
    int limit = ApiRequestService.pageSize,
    String? serviceDate,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerRunList),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'page': page,
        'limit': limit,
        if (serviceDate != null) 'serviceDate': serviceDate,
      },
    );
  }

  Future<DioApiResponse> runDetail(String runId) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.partnerRunDetail,
        <String, String>{'run': runId},
      ),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// Manual run creation. Used when the nightly manifest job has not produced one,
  /// for example for an on-demand one-time order.
  Future<DioApiResponse> createRun({
    required String serviceDate,
    required String slotId,
    String? agentId,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerRunCreate),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'serviceDate': serviceDate,
        'slot': slotId,
        if (agentId != null) 'agent': agentId,
      },
    );
  }

  Future<DioApiResponse> cancelRun(String runId, String reason) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.partnerRunCancel,
        <String, String>{'run': runId},
      ),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'reason': reason},
    );
  }

  //// Cans / deposit ////

  Future<DioApiResponse> cans({
    int page = 1,
    int limit = ApiRequestService.pageSize,
    String? status,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerCanList),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      },
    );
  }

  Future<DioApiResponse> reconcileCans(
    String runId,
    Map<String, dynamic> counts,
  ) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.partnerCanReconcile,
        <String, String>{'run': runId},
      ),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: counts,
    );
  }

  //// Manifest ////

  Future<DioApiResponse> manifestPreview({String? serviceDate}) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerManifestPreview),
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{if (serviceDate != null) 'serviceDate': serviceDate},
    );
  }

  Future<DioApiResponse> manifestSummary({String? serviceDate}) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerManifestSummary),
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{if (serviceDate != null) 'serviceDate': serviceDate},
    );
  }

  Future<DioApiResponse> manifestForecast({int days = 3}) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerManifestForecast),
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'days': days},
    );
  }

  Future<DioApiResponse> manifestGenerate(String serviceDate) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerManifestGenerate),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'serviceDate': serviceDate},
    );
  }

  //// Procurement ////

  Future<DioApiResponse> createProvider(Map<String, dynamic> provider) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerProviderCreate),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: provider,
    );
  }

  Future<DioApiResponse> updateProvider(
    String providerId,
    Map<String, dynamic> changes,
  ) async {
    return ApiRequestService.makeRequest(
      await _path(
        DairyPartnerEndpoints.partnerProviderUpdate,
        <String, String>{'provider': providerId},
      ),
      method: 'PATCH',
      token: await _authRepository.authToken(),
      body: changes,
    );
  }

  Future<DioApiResponse> recordCollection(Map<String, dynamic> intake) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerCollectionCreate),
      method: 'POST',
      token: await _authRepository.authToken(),
      body: intake,
    );
  }

  Future<DioApiResponse> collections({
    int page = 1,
    int limit = ApiRequestService.pageSize,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerCollectionList),
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'page': page, 'limit': limit},
    );
  }

  Future<DioApiResponse> batches({
    int page = 1,
    int limit = ApiRequestService.pageSize,
  }) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerBatchList),
      method: 'GET',
      token: await _authRepository.authToken(),
      body: <String, dynamic>{'page': page, 'limit': limit},
    );
  }

  //// Money ////

  Future<DioApiResponse> earnings({String? from, String? to}) async {
    final Map<String, String> query = <String, String>{
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    };
    return ApiRequestService.makeRequest(
      _withQuery(await _path(DairyPartnerEndpoints.partnerEarnings), query),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  /// The platform's commission on this outlet's sales.
///
/// Not a separate call: the figure is part of the `earnings` payload, because
/// commission is one of several figures computed from the same orders. Splitting
/// it would mean two requests over one dataset, and the two could disagree at a
/// period boundary.
///
/// The standalone `partnerCommission` endpoint remains in `EXPECTED_PENDING` in
/// `verify.dairy.api.contract.js`; it is superseded by this payload rather than
/// awaiting a build.
Future<DioApiResponse> commission({String? from, String? to}) async {
    final DioApiResponse response = await earnings(from: from, to: to);

    if (response.errorType != NetErrorType.none) {
      return response;
    }

    final Map<String, dynamic> body = decodeBody(response);
    // Named `figures`, not `earnings`: the method above already owns that name in
    // this scope.
    final Map<String, dynamic> figures = Map<String, dynamic>.from(
      (body['earnings'] as Map?) ?? <String, dynamic>{},
    );

    // Re-wrapped in the same envelope the dedicated endpoint would have used, so
    // a caller written against either shape keeps working.
    return DioApiResponse(
      body: jsonEncode(<String, dynamic>{
        'commission': <String, dynamic>{
          'commissionBase': figures['commissionBase'],
          'ratePercentage': figures['ratePercentage'],
          'commissionBasis': figures['commissionBasis'],
          'commissionAmount': figures['commissionAmount'],
        },
      }),
      statusCode: response.statusCode,
      errorType: NetErrorType.none,
      response: response.response,
    );
  }

  Future<DioApiResponse> settlements({
    int page = 1,
    int limit = ApiRequestService.pageSize,
  }) async {
    final String endpoint = await _path(DairyPartnerEndpoints.partnerSettlements);
    return ApiRequestService.makeRequest(
      _withQuery(endpoint, <String, String>{'page': '$page', 'limit': '$limit'}),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> settlementDetail(String settlementId) async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerSettlementDetail,
          <String, String>{'settlement': settlementId}),
      method: 'GET',
      token: await _authRepository.authToken(),
    );
  }

  Future<DioApiResponse> requestSettlement() async {
    return ApiRequestService.makeRequest(
      await _path(DairyPartnerEndpoints.partnerSettlementRequest),
      method: 'POST',
      token: await _authRepository.authToken(),
    );
  }
}
