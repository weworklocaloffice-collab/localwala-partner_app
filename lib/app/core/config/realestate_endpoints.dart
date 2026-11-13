/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:partner/app/core/config/api_endpoints.dart';

/// Real Estate module endpoints.
///
/// Vendor calls land under `/v1/realestate/vendor`, executive calls under
/// `/v1/realestate/executive`, both verified against
/// `API/src/modules/realestate/routes/realestate.{vendor,executive}.route.js`.
/// The category catalogue is public (`/v1/realestate/public`) — the vendor
/// listing form reads it without a session.
///
/// Auth: the vendor surface resolves the actor from the access token
/// (`realestateTenantMiddleware`); the executive surface refuses vendors
/// with 403 (`executiveAuth`). Neither file takes an id for the actor —
/// doc §7.1 — so none of these templates carry one either.
///
/// Role determines which subset an authenticated session may call. The
/// guards are enforced server side; a vendor session that reaches an
/// executive path gets a 403, not an empty object (plan §3.1.1).
class RealEstateEndpoints {
  const RealEstateEndpoints._();

  //// Vendor — self ////

  static const String vendorRegister = 'v1/realestate/vendor/register';
  static const String vendorMe = 'v1/realestate/vendor/me';
  static const String vendorSubmitForReview =
      'v1/realestate/vendor/submit-for-review';
  static const String vendorDashboard = 'v1/realestate/vendor/dashboard';

  //// Vendor — packages and orders (BR-02, BR-05) ////

  static const String vendorPackages = 'v1/realestate/vendor/packages';
  static const String vendorPackage = 'v1/realestate/vendor/packages/{code}';
  static const String vendorPackagePurchase =
      'v1/realestate/vendor/packages/{code}/purchase';
  static const String vendorOrders = 'v1/realestate/vendor/orders';
  static const String vendorOrder = 'v1/realestate/vendor/orders/{id}';
  static const String vendorOrderPay = 'v1/realestate/vendor/orders/{id}/pay';
  static const String vendorOrderCancel =
      'v1/realestate/vendor/orders/{id}/cancel';
  static const String vendorEntitlements = 'v1/realestate/vendor/entitlements';

  //// Shared payment handoff (public routes; the initiation id is the link) ////

  static const String paymentMake = 'v1/public/payments/makePayment/{id}';
  static const String paymentSuccess = 'v1/public/payments/paid_success/{id}';

  //// Vendor — properties ////

  static const String vendorProperties = 'v1/realestate/vendor/properties';
  static const String vendorProperty = 'v1/realestate/vendor/properties/{id}';
  static const String vendorPropertySubmit =
      'v1/realestate/vendor/properties/{id}/submit';
  static const String vendorPropertyWithdraw =
      'v1/realestate/vendor/properties/{id}/withdraw';
  static const String vendorPropertyStatus =
      'v1/realestate/vendor/properties/{id}/status/{status}';

  //// Vendor — documents (BR-18, BR-21) ////

  static const String vendorPropertyDocuments =
      'v1/realestate/vendor/properties/{id}/documents';
  static const String vendorPropertyDocument =
      'v1/realestate/vendor/properties/{id}/documents/{documentId}';

  //// Vendor — pipeline (read-only; IDOR closes with 404) ////

  static const String vendorLeads = 'v1/realestate/vendor/leads';
  static const String vendorLead = 'v1/realestate/vendor/leads/{id}';
  static const String vendorVisits = 'v1/realestate/vendor/visits';
  static const String vendorVisit = 'v1/realestate/vendor/visits/{id}';
  static const String vendorHolds = 'v1/realestate/vendor/holds';
  static const String vendorCustomers = 'v1/realestate/vendor/customers';

  //// Vendor — analytics and money (BR-02: commissions never mix with package spend) ////

  static const String vendorAnalytics = 'v1/realestate/vendor/analytics';
  static const String vendorCommissions = 'v1/realestate/vendor/commissions';
  static const String vendorSales = 'v1/realestate/vendor/sales';
  static const String vendorSale = 'v1/realestate/vendor/sales/{id}';

  //// Executive — self and dashboard ////

  static const String executiveMe = 'v1/realestate/executive/me';
  static const String executiveDashboard = 'v1/realestate/executive/dashboard';
  static const String executiveLocation = 'v1/realestate/executive/location';

  //// Executive — visits (BR-08: named transitions, never a generic setter) ////

  static const String executiveVisits = 'v1/realestate/executive/visits';
  static const String executiveVisit = 'v1/realestate/executive/visits/{id}';
  static const String executiveVisitAccept =
      'v1/realestate/executive/visits/{id}/accept';
  static const String executiveVisitCheckIn =
      'v1/realestate/executive/visits/{id}/check_in';
  static const String executiveVisitComplete =
      'v1/realestate/executive/visits/{id}/complete';
  static const String executiveVisitCancel =
      'v1/realestate/executive/visits/{id}/cancel';
  static const String executiveVisitNotes =
      'v1/realestate/executive/visits/{id}/notes';

  //// Executive — interest (BR-09: closed level + reason) and follow-ups ////

  static const String executiveVisitInterest =
      'v1/realestate/executive/visits/{id}/interest';
  static const String executiveLeadFollowUps =
      'v1/realestate/executive/leads/{leadId}/followups';
  static const String executiveFollowUpComplete =
      'v1/realestate/executive/followups/{id}/complete';

  //// Executive — leads and read-only property ////

  static const String executiveLeads = 'v1/realestate/executive/leads';
  static const String executiveLead = 'v1/realestate/executive/leads/{leadId}';
  static const String executiveProperty =
      'v1/realestate/executive/properties/{id}';

  //// Executive — money + queue reads (plan §11.4, all token-scoped) ////

  static const String executiveCommissions =
      'v1/realestate/executive/commissions';
  static const String executiveHolds = 'v1/realestate/executive/holds';
  static const String executiveHold = 'v1/realestate/executive/holds/{id}';
  static const String executiveLoans = 'v1/realestate/executive/loans';
  static const String executiveLoan = 'v1/realestate/executive/loans/{id}';
  static const String executiveSales = 'v1/realestate/executive/sales';
  static const String executiveSale = 'v1/realestate/executive/sales/{id}';
  static const String executiveSettlements =
      'v1/realestate/executive/settlements';
  static const String executiveNotifications =
      'v1/realestate/executive/notifications';
  static const String executiveNotificationRead =
      'v1/realestate/executive/notifications/{id}/read';

  //// Executive — follow-ups (plan §11.4 read-only list; writes stay on
  //// the transition routes above) ////

  static const String executiveFollowUps = 'v1/realestate/executive/followups';

  //// Public catalogue (no session; used by the vendor listing form) ////

  static const String publicCategories = 'v1/realestate/public/categories';
  static const String publicCategoriesGrouped =
      'v1/realestate/public/categories/grouped';
  static const String publicCategory = 'v1/realestate/public/categories/{key}';

  /// Fills `{name}` placeholders in [template] with [values].
  ///
  /// Shared with the dairy endpoints: one resolver, one behaviour (a
  /// placeholder with no value throws rather than producing a URL with a
  /// literal `{id}` in it).
  static String resolve(String template, Map<String, String> values) {
    return DairyPartnerEndpoints.resolve(template, values);
  }
}
