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
 * WeWorkLocal is a technology platform that connects
 * customers, vendors, service providers, and delivery
 * partners through a unified digital ecosystem.
 *
 * This source code, including all associated assets,
 * APIs, databases, business logic, designs, and
 * documentation, is proprietary to WeWorkLocal.
 *
 * Unauthorized copying, modification, distribution,
 * publication, resale, reverse engineering, or use of
 * this software without prior written authorization is
 * strictly prohibited.
 */

/// Local Stores module endpoints.
///
/// Verified against the LIVE routers on 2026-10-13: every path below was read out of
/// `API/src/modules/stores/routes/` and cross-checked by
/// `API/scripts/verify.stores.postman.js`, which fails if this file drifts from the real
/// surface. That matters because the stores vertical has no hand-written API reference —
/// `Resource/postman_collection.json` held zero stores endpoints until this module existed.
///
/// ## The outlet NEVER appears in a path (BR-38)
///
/// The active outlet is a server-side session property. The client cannot send an outlet id
/// to widen a query, so there is deliberately no `/partner/outlets/{outlet}/orders` shape
/// here. Choosing an outlet is `POST /partner/session/outlet`, and after that the server
/// scopes every subsequent call.
///
/// `{order}` / `{delivery}` placeholders resolve through the repository, which throws rather
/// than issuing a request against a literal placeholder.
class StoresPartnerEndpoints {
  const StoresPartnerEndpoints._();

  //// Session and scope ////

  /// Outlet picker — the permitted set for this session (BR-38).
  static const String scope = 'v1/stores/partner/scope';

  /// Switches the active outlet. Server-validated against the user's role scope.
  static const String sessionOutlet = 'v1/stores/partner/session/outlet';

  static const String myOutlets = 'v1/stores/partner/outlets';
  static const String subscriptions = 'v1/stores/partner/subscriptions';
  static const String customers = 'v1/stores/partner/customers';
  static const String recurringPlans = 'v1/stores/partner/recurring-plans';
  static const String recurringPlan = 'v1/stores/partner/recurring-plans/{plan}';
  static const String subscriptionDemand = 'v1/stores/partner/subscriptions/demand';
  static const String myOutlet = 'v1/stores/partner/outlets/{outlet}';
  static const String myChain = 'v1/stores/partner/chain';

  /// The BR-32 capability row. The app renders its banners from this rather than
  /// re-implementing the matrix in Dart, so the two cannot disagree.
  static const String capabilities = 'v1/stores/partner/capabilities';

  static const String team = 'v1/stores/partner/team';

  //// Featured placements — paid visibility ////

  /// What the outlet has live, pending, or in history. Verified against
  /// `stores.catalog.route.js`: a separate `stores.featured.route.js` declares the same
  /// paths but is required by nothing, so THESE are the live ones, not those.
  static const String featuredList = 'v1/stores/partner/featured';
  static const String featuredDetail = 'v1/stores/partner/featured/{placement}';
  static const String featuredPending = 'v1/stores/partner/featured/pending';
  static const String featuredApprove =
      'v1/stores/partner/featured/{placement}/approve';
  static const String featuredReject =
      'v1/stores/partner/featured/{placement}/reject';

  //// Orders ////

  static const String orderList = 'v1/stores/partner/orders';

  /// Manual order entry (§10.3.1). Same path as the list, differing by verb —
  /// the server spreads the body into `createOrder` with `customer`, `outlet` and
  /// `chain` stamped from the token, so a counter sale can never claim another
  /// outlet or impersonate a customer.
  static const String orderCreate = 'v1/stores/partner/orders';

  static const String orderDetail = 'v1/stores/partner/orders/{order}';

  /// Lifecycle target is a PATH PARAMETER (`.../{order}/{status}`) so a client cannot POST
  /// an arbitrary status; the service transition table is the second gate.
  static const String orderTransition =
      'v1/stores/partner/orders/{order}/{status}';
  static const String orderCancel = 'v1/stores/partner/orders/{order}/cancel';
  static const String orderReject = 'v1/stores/partner/orders/{order}/reject';
  static const String orderPickList =
      'v1/stores/partner/orders/{order}/pick-list';
  static const String orderPickItem =
      'v1/stores/partner/orders/{order}/pick-item';
  static const String orderPacking = 'v1/stores/partner/orders/{order}/packing';
  static const String orderFulfilmentSummary =
      'v1/stores/partner/orders/{order}/fulfilment-summary';

  //// Store-owned delivery ////

  static const String deliveryAssign = 'v1/stores/delivery/assign';
  static const String deliveryByOrder = 'v1/stores/delivery/order/{order}';
  static const String deliveryPartnerList = 'v1/stores/delivery';
  static const String deliveryAvailableDrivers =
      'v1/stores/delivery/drivers/available';

  //// Inventory (outlet-scoped; the server resolves the outlet) ////

  static const String stockList = 'v1/stores/inventory/stock';
  static const String stockAdjust = 'v1/stores/inventory/stock/adjust';
  static const String stockLow = 'v1/stores/inventory/stock/low';
  static const String movements = 'v1/stores/inventory/movements';

  //// Catalogue ////

  static const String catalogProducts = 'v1/stores/catalog/products';
  static const String catalogProductsImport =
      'v1/stores/catalog/products/import';
  static const String catalogProduct = 'v1/stores/catalog/products/{product}';
  static const String catalogBrandRequest = 'v1/stores/catalog/brands/request';
  static const String catalogBrandRequests = 'v1/stores/catalog/brands/requests';
  static const String catalogCategories = 'v1/stores/catalog/categories';
  static const String catalogSubcategories = 'v1/stores/catalog/subcategories';
  static const String catalogBrands = 'v1/stores/catalog/brands';
  static const String catalogBrandCertification =
      'v1/stores/catalog/brands/{brand}/certifications';
  static const String productForm = 'v1/stores/catalog/product-form';
  static const String generateVariants =
      'v1/stores/catalog/products/{product}/variants/generate';

  //// Dashboard ////

  static const String dashboard = 'v1/stores/analytics/dashboard';
  static const String policies = 'v1/stores/policies';
  static const String reviews = 'v1/stores/reviews';
  static const String analyticsChain = 'v1/stores/analytics/chain';
  static const String dispatch = 'v1/stores/partner/orders';
  static const String chainAnalytics = 'v1/stores/analytics/chain';

  //// Store-owned fleet (BR-04..BR-08: the store's own drivers) ////

  static const String driverList = 'v1/stores/drivers';
  static const String driverDetail = 'v1/stores/drivers/{driver}';
  static const String driverSuspend = 'v1/stores/drivers/{driver}/suspend';
  static const String driverReactivate =
      'v1/stores/drivers/{driver}/reactivate';
  static const String driverAvailability =
      'v1/stores/drivers/{driver}/availability';

  //// Post-sale ////

  static const String returnList = 'v1/stores/returns';
  static const String exchangeList = 'v1/stores/exchanges';
  static const String returnDetail = 'v1/stores/returns/{return}';
  static const String returnStatus = 'v1/stores/returns/{return}/{status}';
  static const String returnRefund = 'v1/stores/returns/{return}/refund';

  static const String warrantyList = 'v1/stores/partner/warranty';
  static const String warrantyStatus =
      'v1/stores/partner/warranty/{warranty}/{status}';

  /// Singular on the partner side — the admin surface uses the plural
  /// `v1/stores/admin/.../settlements/{settlement}` instead. Verified against the live
  /// routers; the two spellings coexist by design.
  static const String settlementList = 'v1/stores/settlement';
  static const String settlementDetail = 'v1/stores/settlement/{settlement}';

  /// Current chain subscription. There is exactly one live row per chain — one live plus
  /// history — so this is a GET of the current one, not a list. Verified against
  /// `stores.catalog.route.js`: `GET /subscription`.
  static const String subscriptionCurrent = 'v1/stores/subscription';

  /// Status is a PATH PARAMETER (`.../{subscription}/{status}`), matching the orders
  /// convention. A client cannot invent a status; the service transition table gates it.
  static const String subscriptionTransition =
      'v1/stores/subscription/{subscription}/{status}';

  /// Starts a gateway payment for the chain subscription (BR-16).
  /// Body: `{ subscription: <id> }`. Returns the PaymentInitiation, not a confirmation.
  static const String subscriptionPay = 'v1/stores/subscription/pay';

  static const String promotionList = 'v1/stores/promotions';

  /// Creates a promotion. Verified against `stores.catalog.route.js` — same path as the
  /// list, differing by verb (POST creates, GET lists).
  static const String promotionCreate = 'v1/stores/promotions';

  /// Tests a code against a cart amount. Returns the promotion and the discount it yields.
  static const String promotionValidate = 'v1/stores/promotions/validate';

  /// Takes a live/scheduled promotion out of circulation, and puts an approved paused one
  /// back on its window. Approval can never be resumed away: the server rejects pending
  /// and rejected drafts with `PROMOTION_NOT_APPROVED`.
  static const String promotionPause = 'v1/stores/promotions/:promotion/pause';
  static const String promotionResume =
      'v1/stores/promotions/:promotion/resume';

  /// Redeemable coupons. A separate ledger from promotions: a coupon always has a code
  /// the customer types, while a promotion may be automatic.
  static const String couponList = 'v1/stores/coupons';
  static const String couponCreate = 'v1/stores/coupons';

  //// Onboarding — a new chain, one step at a time ////

  /// The applicant's draft. Created lazily by the server on first read.
  static const String application = 'v1/stores/application';

  /// PATCH saves ONE step key; the server shallow-merges and recomputes
  /// `currentStep`/`completedSteps`/`incompleteSteps`. The client must render progress
  /// from that response, never from a local counter.
  static const String applicationSubmit = 'v1/stores/application/submit';

  static const String complaintList = 'v1/stores/partner/complaints';
  static const String complaintStatus =
      'v1/stores/partner/complaints/{complaint}/{status}';
}

/// The store-driver role's surface, in the same Partner app.
///
/// BR-05 forbids the LocalWala platform fleet (`Deliveryman_app`), so a store driver never
/// opens that app — they open this one against their own outlet.
class StoresDriverEndpoints {
  const StoresDriverEndpoints._();

  static const String deliveryList = 'v1/stores/deliveries';
  static const String deliveryDetail = 'v1/stores/deliveries/{delivery}';

  /// Lifecycle target as a path parameter, matching the partner convention.
  static const String deliveryStatus =
      'v1/stores/deliveries/{delivery}/{status}';

  /// BR-29 — completing a handover REQUIRES the customer's OTP.
  static const String deliveryVerifyOtp =
      'v1/stores/deliveries/{delivery}/deliver';

  static const String deliveryFail = 'v1/stores/deliveries/{delivery}/fail';

  /// The drop-off address lives on the ORDER, and the partner order route rejects a
  /// driver token. This read returns only the handover fields (address, payment, note).
  static const String deliveryOrder = 'v1/stores/deliveries/{delivery}/order';

  static const String earnings = 'v1/stores/earnings';
}

/// Substitute the placeholders the way the sibling verticals do.
///
/// Throws on an unresolved placeholder rather than issuing a request against a literal
/// `{order}` — a request to `/orders/{order}` 404s and looks like a server fault instead of
/// a caller bug.
///
/// THIS USED TO DO THE OPPOSITE. Every parameter defaulted to `''`, so a missed argument
/// quietly produced `v1/stores/partner/orders/` — a request to a collection endpoint, which
/// 404s with a message that points at the server while the fault was always in the caller.
/// The doc comment above promised a throw that the code never performed; a comment is not a
/// guard.
///
/// Detection substitutes a SENTINEL for each missing value rather than an empty string, and
/// then looks for what is left. The obvious alternative — substitute `''`, then scan for a
/// surviving `{...}` — does not work, because by the time you scan, the placeholder has
/// already been erased along with the value. That version passed `orders/{order}` with no
/// order through and returned `v1/stores/partner/orders/` without complaint.
///
/// Because the sentinel stands in for the VALUE, a parameter nobody remembered to add to
/// this signature is caught too, provided the path declares it.
  String storesResolve(
  String path, {
  String? brand,
  String? order,
  String? outlet,
  String? product,
  String? delivery,
  String? driver,
  String? warranty,
  String? subscription,
  String? settlement,
  String? status,
  String? returnId,
  String? complaint,
  String? placement,
  String? promotion,
}) {
  // One map instead of twelve chained `?? ''` calls.
  final Map<String, String?> supplied = <String, String?>{
    'brand': brand,
    'order': order,
    'outlet': outlet,
    'product': product,
    'delivery': delivery,
    'driver': driver,
    'warranty': warranty,
    'subscription': subscription,
    'settlement': settlement,
    'status': status,
    'return': returnId,
    'complaint': complaint,
    'placement': placement,
    'promotion': promotion,
  };

  // Validation happens BEFORE substitution, because substitution destroys the evidence.
  // Both earlier attempts failed the same way: one substituted `''` and then scanned for a
  // surviving `{...}` (there was none, the placeholder had just been erased); the other
  // substituted a sentinel and scanned for `{...}<sentinel>` (again no placeholder, because
  // the sentinel HAD replaced it). Checking what the path asks for, against what the caller
  // supplied, has to happen while the path is still intact.
  for (final RegExpMatch placeholder in RegExp(r'\{(\w+)\}').allMatches(path)) {
    final String name = placeholder.group(1)!;
    final String? value = supplied[name];
    if (value == null || value.isEmpty) {
      throw ArgumentError(
        'storesResolve: "$name" was not supplied for "$path". Refusing to send a request '
        'with a missing path segment; it would be answered by an unrelated route, or 404 '
        'with a message that blames the server for a caller bug.',
      );
    }
  }

  // A placeholder this function has no parameter for is still a caller bug rather than a
  // server one, so it is named here instead of going out as a literal `{name}`.
  return path.replaceAllMapped(
    RegExp(r'\{(\w+)\}'),
    (Match m) => supplied[m.group(1)!] ?? '',
  );
}
