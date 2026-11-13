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

/// Vertical-neutral sign-in for the Partner app.
///
/// Authentication is shared by every role this binary can hold; the role in the
/// user record selects that vertical's own profile payload.
class PartnerAppEndpoints {
  const PartnerAppEndpoints._();

  static const String loginOtpVerification =
      'v1/auth/partner_app/login_po_verification';
  static const String login = 'v1/auth/partner_app/login_po/';
  static const String verifyOtp = 'v1/auth/verifyOTP';
  static const String refreshToken = 'v1/auth/refresh-tokens-app';
  static const String logout = 'v1/auth/logout';
}

/// Local Services self-registration. Authentication itself is shared through
/// [PartnerAppEndpoints].
class LocalServicesAuthEndpoints {
  const LocalServicesAuthEndpoints._();

  static const String registerSendOtp =
      'v1/local-services/auth/register/send_otp';
  static const String registerPartner =
      'v1/local-services/auth/register/partner';
}

/// Real Estate self-registration. Authentication itself is shared through
/// [PartnerAppEndpoints].
class RealEstateAuthEndpoints {
  const RealEstateAuthEndpoints._();

  static const String registerSendOtp = 'v1/realestate/auth/register/send_otp';
  static const String registerPartner = 'v1/realestate/auth/register/partner';
}

/// Stores applicants complete business onboarding after creating an account.
class StoresAuthEndpoints {
  const StoresAuthEndpoints._();

  static const String registerSendOtp = 'v1/stores/auth/register/send_otp';
  static const String registerPartner = 'v1/stores/auth/register/partner';
}

/// Jhatka self-registration. Authentication itself is shared through
/// [PartnerAppEndpoints].
class JhatkaAuthEndpoints {
  const JhatkaAuthEndpoints._();

  static const String registerSendOtp =
      'v1/jhatka/public/auth/register/send_otp';
  static const String registerPartner =
      'v1/jhatka/public/auth/register/partner';
  static const String availableRoles =
      'v1/jhatka/partner/profile/available_roles';
  static const String switchRole = 'v1/jhatka/partner/profile/switch_role';
  static const String profileMe = 'v1/jhatka/partner/profile/me';

  // These are platform-level public endpoints, not dairy business endpoints.
  static const String registerCities =
      'v1/public/register/getBasicDataDairyRequest';
  static const String localitiesFromCity =
      'v1/public/localities_from_city/{city}';
}

/// Dairy module endpoints are mounted at `/v1/dairy`.
///
/// Role determines which subset an authenticated session may call.
/// `dairyRoleEndpoints` guards are enforced server side in
/// `API/src/middlewares/auth.factory.js` via `config/roles.js`.
class DairyPartnerEndpoints {
  const DairyPartnerEndpoints._();

  //// Public ////
  // Paths verified against API/src/routes/v1/auth.route.js. There is no
  // `/dairy/login_po/` equivalent before Phase 0 — it is mounted alongside the
  // kitchen chain and mirrors it exactly.
  static const String loginOtpVerification =
      'v1/auth/dairy/login_po_verification';
  static const String login = 'v1/auth/dairy/login_po/';
  static const String verifyOtp = 'v1/auth/verifyOTP';
  static const String refreshToken = 'v1/auth/refresh-tokens-app';
  static const String logout = 'v1/auth/logout';

  //// Session / role resolution ////
  static const String profileMe = 'v1/dairy/profile/me';
  static const String availableRoles = 'v1/dairy/profile/available_roles';
  static const String switchRole = 'v1/dairy/profile/switch_role';
  static const String businessProfile = 'v1/dairy/catalog/businesses/{id}';
  static const String dairyCategories = 'v1/dairy/catalog/categories';
  static const String dairySubCategories = 'v1/dairy/catalog/sub_categories';
  static const String dairyBrands = 'v1/dairy/catalog/brands';

  //// Self-registration ////
  // Unauthenticated by design — a dairy operator or rider is recruited in the
  // field. The server-side role allowlist is the security boundary.
  static const String registerSendOtp = 'v1/dairy/auth/register/send_otp';
  static const String registerPartner = 'v1/dairy/auth/register/partner';
  static const String registerDriver = 'v1/dairy/auth/register/driver';
  static const String driverOnboardingStatus = 'v1/dairy/driver/onboarding/status';

  /// Cities the platform serves, for the outlet form's first dropdown.
  ///
  /// Public on purpose: the form is filled before the phone is verified, so an
  /// authenticated endpoint would not be reachable at the moment it is needed.
  /// The response is a projection — id, name, location, translations — and
  /// active cities only.
  static const String registerCities =
      'v1/public/register/getBasicDataDairyRequest';

  /// Localities within a city, for the second dropdown. Shared with the
  /// restaurant registration flow rather than duplicated per vertical; the
  /// server filters by city, so the cascade cannot be short-circuited.
  static const String localitiesFromCity =
      'v1/public/localities_from_city/{city}';

  //// Partner: dashboard ////
  /// One call for the whole home screen. Outlet context is sent in a header
  /// and revalidated by the API on every request.
  static const String partnerDashboard = 'v1/dairy/partner/dashboard';
  static const String partnerOutlets = 'v1/dairy/partner/outlets';
  static const String partnerOutletSelect = 'v1/dairy/partner/outlets/select';
  static const String partnerSalesReport = 'v1/dairy/partner/reports/sales';
  static const String partnerSalesExport = 'v1/dairy/partner/reports/sales/export';
  static const String partnerSupportTickets = 'v1/dairy/partner/support/tickets';
  static const String partnerSupportTicket = 'v1/dairy/partner/support/tickets/{ticket}';
  static const String partnerSupportReplies = 'v1/dairy/partner/support/tickets/{ticket}/replies';
  static const String partnerSupportChat = 'v1/dairy/partner/support/chat';
  static const String partnerSupportChatMessages = 'v1/dairy/partner/support/chat/{room}/messages';
  static const String partnerSupportChatHandover = 'v1/dairy/partner/support/chat/{room}/handover';
  static const String partnerBusinessProfile = 'v1/dairy/partner/profile/business';
  static const String partnerFranchiseJoiningFeePay =
      'v1/dairy/partner/franchise/joining-fee/pay';
  static const String partnerCoverage = 'v1/dairy/partner/coverage';
  static const String partnerCoverageRequests =
      'v1/dairy/partner/coverage/requests';
  static const String partnerAvailability = 'v1/dairy/partner/availability';
  static const String partnerMarketingPackages =
      'v1/dairy/partner/marketing/packages';
  static const String partnerMarketingCampaigns =
      'v1/dairy/partner/marketing/campaigns';
  static const String partnerMarketingCampaignPay =
      'v1/dairy/partner/marketing/campaigns/{campaign}/pay';
  static const String partnerMarketingCoupons = 'v1/dairy/partner/marketing/coupons';
  static const String partnerMarketingCouponDisable =
      'v1/dairy/partner/marketing/coupons/{coupon}/disable';
  static const String partnerMarketingCouponReport =
      'v1/dairy/partner/marketing/coupons/{coupon}/report';

  //// Partner: catalogue ////
  // The partner product list is scoped to the authenticated outlet by the API.
  static const String partnerProducts = 'v1/dairy/partner/products';
  static const String partnerProductCreate = 'v1/dairy/partner/products';
  static const String partnerProductUpdate = 'v1/dairy/partner/products/{id}';
  static const String partnerProductDelete = 'v1/dairy/partner/products/{id}';
  static const String partnerSkuCreate = 'v1/dairy/partner/skus';
  static const String partnerSkuUpdate = 'v1/dairy/partner/skus/{id}';

  //// Partner: inventory ////
  static const String partnerInventoryList = 'v1/dairy/partner/skus/list';
  static const String partnerInventoryUpdate =
      'v1/dairy/partner/skus/{id}/stock';
  static const String partnerSkuLots = 'v1/dairy/partner/skus/{id}/lots';
  static const String partnerInventoryMovements =
      'v1/dairy/partner/inventory/movements';
  static const String partnerInventoryReport = 'v1/dairy/partner/inventory/report';
  static const String partnerSkuLotWriteOff =
      'v1/dairy/partner/skus/{id}/lots/{lot}/write-off';
  static const String partnerSkuLotDisposition =
      'v1/dairy/partner/skus/{id}/lots/{lot}/disposition';

  /// Not built yet on the API — see `partnerDashboard`.
  static const String partnerStockAdjust = 'v1/dairy/partner/inventory/adjust';

  //// Partner: orders ////
  static const String partnerOrderList = 'v1/dairy/partner/orders/list';
  static const String partnerOrderSummary = 'v1/dairy/partner/orders/summary';
  static const String partnerOrderDispatch =
      'v1/dairy/partner/orders/{order}/dispatch';
  // Accept / reject / ready are one status route, not three verbs.
  static const String partnerOrderStatus = 'v1/dairy/orders/{status}/{order}';
  static const String partnerOrderAccept = 'v1/dairy/orders/confirmed/{order}';
  static const String partnerOrderReject = 'v1/dairy/orders/cancelled/{order}';
  static const String partnerOrderReady = 'v1/dairy/orders/preparing/{order}';

  //// Partner: subscriptions ////
  // Subscriptions. Live on the API: the partner sees the plans sold by their own
  // outlet, and may pause or resume one of them.
  static const String partnerSubscriptionList =
      'v1/dairy/partner/subscriptions/list';
  static const String partnerSubscriptionPause =
      'v1/dairy/partner/subscriptions/{subscription}/pause';
  static const String partnerSubscriptionResume =
      'v1/dairy/partner/subscriptions/{subscription}/resume';

  //// Partner: customers ////
  // Derived from the outlet's own orders and plans, so "who buys from me" comes
  // from real orders rather than a list maintained by hand.
  static const String partnerCustomerList = 'v1/dairy/partner/customers/list';

  //// Partner: delivery drivers (own fleet) ////
  // Live. An invitation is a phone number, not an account: the rider joins when
  // they register with it, which is what proves the invitation was real.
  static const String partnerDriverList = 'v1/dairy/partner/drivers/list';
  static const String partnerDriverInvite = 'v1/dairy/partner/drivers/invite';
  static const String partnerDriverCreate = 'v1/dairy/partner/drivers/create';
  static const String partnerDriverInvites = 'v1/dairy/partner/drivers/invites';
  static const String partnerDriverInviteRevoke =
      'v1/dairy/partner/drivers/invites/{invite}';
  static const String partnerDriverActivationReissue =
      'v1/dairy/partner/drivers/invites/{invite}/reissue';
  static const String partnerDriverApprove =
      'v1/dairy/partner/drivers/{id}/approval';
  static const String partnerDriverRemove = 'v1/dairy/partner/drivers/{id}';
  static const String partnerDriverPayout =
      'v1/dairy/partner/drivers/{id}/payout';

  //// Partner: delivery runs (monitor) ////
  static const String partnerRunList = 'v1/dairy/partner/runs/list';
  static const String partnerRunDetail = 'v1/dairy/partner/runs/detail/{run}';
  static const String partnerRunCreate = 'v1/dairy/partner/runs/create';
  static const String partnerRunCancel = 'v1/dairy/partner/runs/cancel/{run}';

  //// Partner: cans / deposit ////
  static const String partnerCanList = 'v1/dairy/partner/cans/list';
  static const String partnerCanCreate = 'v1/dairy/partner/cans/create';
  static const String partnerCanImport = 'v1/dairy/partner/cans/import';
  static const String partnerCanReconcile =
      'v1/dairy/partner/cans/reconcile/{run}';
  static const String partnerCanWriteOff =
      'v1/dairy/partner/cans/write_off/{can}';

  //// Partner: manifest ////
  static const String partnerManifestPreview =
      'v1/dairy/partner/manifest/preview';
  static const String partnerManifestSummary =
      'v1/dairy/partner/manifest/summary';
  static const String partnerManifestForecast =
      'v1/dairy/partner/manifest/forecast';
  static const String partnerManifestGenerate =
      'v1/dairy/partner/manifest/generate';

  //// Partner: procurement ////
  static const String partnerProviderCreate = 'v1/dairy/partner/providers';
  static const String partnerProviderUpdate =
      'v1/dairy/partner/providers/{provider}';
  static const String partnerCollectionCreate = 'v1/dairy/partner/collections';
  static const String partnerCollectionList = 'v1/dairy/partner/collections';
  static const String partnerBatchList = 'v1/dairy/partner/batches';

  //// Partner: earnings, commission, settlements ////
  // Not built yet on the API. `partnerSettlements` does exist, scoped to the
  // outlet; the earnings and commission reports do not.
  static const String partnerEarnings = 'v1/dairy/partner/earnings';
  static const String partnerCommission = 'v1/dairy/partner/commission';
  static const String partnerSettlements = 'v1/dairy/partner/settlements/list';
  static const String partnerSettlementRequest =
      'v1/dairy/partner/settlements/request';
  static const String partnerSettlementDetail =
      'v1/dairy/partner/settlements/detail/{settlement}';

  //// Delivery agent: manifest ////
  // No `{id}` on any rider route. The API resolves the rider from the access
  // token, so there is no rider id in these paths to send — and nothing for a
  // tampered client to change.
  static const String driverRunToday = 'v1/dairy/driver/run/today';
  static const String driverRunHistory = 'v1/dairy/driver/runs/history';
  static const String driverRunDetail = 'v1/dairy/driver/runs/detail/{run}';
  static const String driverRunStart = 'v1/dairy/driver/runs/start/{run}';
  static const String driverRunComplete = 'v1/dairy/driver/runs/complete/{run}';
  static const String driverRunPingLocation = 'v1/dairy/driver/runs/{run}/location';

  /// Fills `{name}` placeholders in [template] with [values].
  ///
  /// A placeholder with no matching value throws rather than producing a request
  /// to a URL with a literal `{run}` in it, which would 404 with no explanation.
  static String resolve(String template, Map<String, String> values) {
    return template.replaceAllMapped(RegExp(r'\{(\w+)\}'), (Match match) {
      final String? value = values[match.group(1)];
      if (value == null || value.isEmpty) {
        throw ArgumentError(
          'Missing "${match.group(1)}" for endpoint $template',
        );
      }
      return Uri.encodeComponent(value);
    });
  }

  //// Delivery agent: stops ////
  // `/driver/stops/:status/:stop` is one route, so skip and fail differ only by
  // the status segment.
  static const String driverStopList = 'v1/dairy/driver/stops/list/{run}';
  static const String driverStopArrive = 'v1/dairy/driver/stops/arrive/{stop}';
  static const String driverStopDeliver =
      'v1/dairy/driver/stops/deliver/{stop}';
  static const String driverStopSkip = 'v1/dairy/driver/stops/skipped/{stop}';
  static const String driverStopFail = 'v1/dairy/driver/stops/failed/{stop}';

  //// Delivery agent: cans ////
  static const String driverPickupScan = 'v1/dairy/driver/cans/pickup_scan';
  static const String driverReturnScan = 'v1/dairy/driver/cans/return_scan';
  static const String driverCanIssueScan = 'v1/dairy/driver/cans/issue_scan';
  static const String driverCanCollectScan =
      'v1/dairy/driver/cans/collect_scan';
  static const String driverCanDepositSummary =
      'v1/dairy/driver/cans/deposit_summary';
  static const String driverCanRunBalance =
      'v1/dairy/driver/cans/run_balance/{run}';

  /// Container rotation, used when a delivery swaps bottles.
  static const String driverContainerSwapPlan =
      'v1/dairy/driver/containers/swap_plan/{id}';
  static const String driverContainerSwapComplete =
      'v1/dairy/driver/containers/swap_complete/{assignment}/{id}';

  //// Delivery agent: earnings ////
  // Live. None of these carry a rider id: the server resolves the rider from the
  // access token, so there is no id for a caller to swap for someone else's.
  static const String driverEarnings = 'v1/dairy/driver/earnings';
  static const String driverCashInHand = 'v1/dairy/driver/cash_in_hand';
  static const String driverCashDeposit = 'v1/dairy/driver/cash_deposit';

  ////// Shared account ////
  // Notifications are live. Scoped to the signed-in account server-side, so
  // there is no user id here to get wrong.
  static const String notificationList = 'v1/dairy/notification/list';
  static const String markAllRead = 'v1/dairy/notification/read_all';
  static const String dismissNotification = 'v1/dairy/notification/{id}';

  // Still not built. A chat needs someone on the other end: the existing support
  // models are restaurant-shaped and there is no admin dairy surface to answer
  // from, so a half-thread would be worse than an honest gap.
  static const String supportChat = 'v1/dairy/support/chat';

  /// The platform's real upload route. Not `/v1/file/upload` — that path does
  /// not exist, so every image and document upload was going to a 404.
  static const String uploadFile = 'v1/file/uploadImage';
}
