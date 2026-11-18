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

/// Jhatka module endpoints, mounted at `/v1/jhatka`.
///
/// Verified against `API/src/routes/v1/index.js` and
/// `API/scripts/list.jhatka.routes.js`. The outlet never appears here —
/// the server derives it from the access token, so there is nothing a
/// client could change to reach another outlet.
///
/// `{order}`/`{delivery}` placeholders resolve through [resolve], which
/// throws rather than issuing a request against a literal `{order}`.
class JhatkaPartnerEndpoints {
  const JhatkaPartnerEndpoints._();

  //// Session — multi-outlet partners (BR-04) switch counters here. ////
  static const String sessionOutlets = 'v1/jhatka/partner/outlets';
  static const String sessionSwitch = 'v1/jhatka/partner/session/outlet';
  static const String sessionScope = 'v1/jhatka/partner/scope';

  //// Customers — outlet's own only, never platform-wide. ////
  static const String customerSearch = 'v1/jhatka/partner/customers/search';

  //// Orders ////
  static const String orderList = 'v1/jhatka/partner/orders';
  static const String orderDetail = 'v1/jhatka/partner/orders/{order}';
  static const String orderInvoice = 'v1/jhatka/partner/orders/{order}/invoice';
  // Intake — the first half of the pipeline. Without these, an order placed by a
  // customer sits at CREATED forever: the list shows it, weighing needs PREPARING,
  // and nothing in between exists. Added late because the backend's OUTLET_RECEIVED
  // state itself had no writer until the lifecycle audit found it.
  static const String orderReceive = 'v1/jhatka/partner/orders/{order}/receive';
  static const String orderAccept = 'v1/jhatka/partner/orders/{order}/accept';
  static const String orderReject = 'v1/jhatka/partner/orders/{order}/reject';
  static const String orderStartPreparation =
      'v1/jhatka/partner/orders/{order}/start-preparation';
  static const String orderWeigh = 'v1/jhatka/partner/orders/{order}/weigh';
  static const String orderPack = 'v1/jhatka/partner/orders/{order}/pack';
  static const String orderReady = 'v1/jhatka/partner/orders/{order}/ready';
  static const String orderDispatch =
      'v1/jhatka/partner/orders/{order}/dispatch';
  static const String orderCollect = 'v1/jhatka/partner/orders/{order}/collect';

  //// Supply (OD-12 companion) ////
  static const String supplyCatalogue = 'v1/jhatka/partner/supply/catalogue';
  static const String supplyModes = 'v1/jhatka/partner/supply/modes';
  static const String supplyRequests = 'v1/jhatka/partner/supply/requests';
  static const String supplyRequestPay =
      'v1/jhatka/partner/supply/requests/{id}/pay';
  static const String supplyLedger = 'v1/jhatka/partner/supply/ledger';
  // Delivery-area adjustment: the partner proposes, admin approves. The
  // platform ceiling rides on the GET, so the form can refuse a doomed number
  // before it leaves the device.
  static const String supplyArea = 'v1/jhatka/partner/supply/area';
  static const String supplyAreaRequests =
      'v1/jhatka/partner/supply/area/requests';
  static const String supplyAreaRequest =
      'v1/jhatka/partner/supply/area/requests/{id}';

  //// Dispatch ////
  static const String outletDrivers = 'v1/jhatka/partner/drivers';

  //// Rider (driver role — outlet riders in the Partner app, by design) ////
  static const String riderDeliveries = 'v1/jhatka/driver/deliveries';
  static const String riderDelivery = 'v1/jhatka/driver/deliveries/{delivery}';
  static const String riderAccept =
      'v1/jhatka/driver/deliveries/{delivery}/accept';
  static const String riderPickup =
      'v1/jhatka/driver/deliveries/{delivery}/pickup';
  static const String riderArrived =
      'v1/jhatka/driver/deliveries/{delivery}/arrived';
  static const String riderOutForDelivery =
      'v1/jhatka/driver/deliveries/{delivery}/out-for-delivery';
  static const String riderDeliver =
      'v1/jhatka/driver/deliveries/{delivery}/deliver';
  static const String riderFail = 'v1/jhatka/driver/deliveries/{delivery}/fail';
  static const String riderCollectCod =
      'v1/jhatka/driver/deliveries/{delivery}/collect-cod';
  static const String riderPod = 'v1/jhatka/driver/pod';
  static const String riderEarnings = 'v1/jhatka/driver/earnings';
  static const String outletDriverUpdate = 'v1/jhatka/partner/drivers/{driver}';
  static const String outletDriverStatus =
      'v1/jhatka/partner/drivers/{driver}/status';

  //// Catalogue (read-only browse; outlet-scoped overrides below) ////
  static const String catalogueCategories = 'v1/jhatka/catalogue/categories';
  static const String catalogueProducts = 'v1/jhatka/catalogue/products';

  //// Price overrides ////
  static const String priceOverrides = 'v1/jhatka/partner/price-overrides';
  static const String priceOverrideApprove =
      'v1/jhatka/partner/price-overrides/{override}/approve';
  static const String priceOverrideRevoke =
      'v1/jhatka/partner/price-overrides/{override}/revoke';

  //// Compliance ////
  static const String compliance = 'v1/jhatka/partner/compliance';
  static const String complianceFssai = 'v1/jhatka/partner/compliance/fssai';
  static const String complianceOutlet = 'v1/jhatka/partner/compliance/outlet';
  static const String complaints = 'v1/jhatka/partner/compliance/complaints';
  static const String complaintRespond =
      'v1/jhatka/partner/compliance/complaints/{id}/respond';
  static const String reviews = 'v1/jhatka/partner/compliance/reviews';
  static const String reviewRespond =
      'v1/jhatka/partner/compliance/reviews/{id}/respond';
  static const String promotions = 'v1/jhatka/partner/compliance/promotions';

  //// Labels ////
  static const String labels = 'v1/jhatka/partner/labels';
  static const String labelDetail = 'v1/jhatka/partner/labels/{label}';
  static const String labelPrint = 'v1/jhatka/partner/labels/{label}/print';
  static const String labelApply = 'v1/jhatka/partner/labels/{label}/apply';
  static const String labelVoid = 'v1/jhatka/partner/labels/{label}/void';
  static const String outletDeliveries = 'v1/jhatka/partner/deliveries';
  static const String outletDeliveryDetail =
      'v1/jhatka/partner/deliveries/{delivery}';

  //// Money ////
  static const String settlementSummary =
      'v1/jhatka/partner/money/settlements/summary';
  static const String settlements = 'v1/jhatka/partner/money/settlements';

  /// Effective commission terms for this outlet. Read-only: the rule is set
  /// by LocalWala admin, so there is no partner-side create/update endpoint.
  static const String commissionTerms =
      'v1/jhatka/partner/money/commission-terms';
  static const String outletAnalytics = 'v1/jhatka/partner/analytics';
  static const String payouts = 'v1/jhatka/partner/money/payouts';
  static const String payoutDetail = 'v1/jhatka/partner/money/payouts/{id}';
  static const String payables = 'v1/jhatka/partner/money/payables';

  //// Subscriptions ////
  static const String subscriptions = 'v1/jhatka/partner/subscriptions';
  static const String subscriptionDetail =
      'v1/jhatka/partner/subscriptions/{subscription}';
  static const String subscriptionPause =
      'v1/jhatka/partner/subscriptions/{subscription}/pause';
  static const String subscriptionResume =
      'v1/jhatka/partner/subscriptions/{subscription}/resume';
  static const String subscriptionCancel =
      'v1/jhatka/partner/subscriptions/{subscription}/cancel';
  static const String subscriptionSkip =
      'v1/jhatka/partner/subscriptions/{subscription}/skip';
  static const String subscriptionItems =
      'v1/jhatka/partner/subscriptions/{subscription}/items';
  static const String occurrenceGenerate =
      'v1/jhatka/partner/subscriptions/occurrences/{occurrence}/generate';
  // Retry a prepaid charge that never arrived. Mints a FRESH initiation — the
  // customer still has to pay; only a gateway callback marks it paid.
  static const String occurrenceRetryBilling =
      'v1/jhatka/partner/subscriptions/occurrences/{occurrence}/retry-billing';

  //// Procurement ////
  static const String suppliers = 'v1/jhatka/partner/inventory/suppliers';
  static const String purchaseOrders =
      'v1/jhatka/partner/inventory/purchase-orders';
  static const String receiptsCreate = 'v1/jhatka/partner/inventory/receipts';
  static const String inventoryAdjust = 'v1/jhatka/partner/inventory/adjust';
  static const String inventoryWastage = 'v1/jhatka/partner/inventory/wastage';
  static const String purchaseOrderPlace =
      'v1/jhatka/partner/inventory/purchase-orders/{po}/place';
  static const String receipts = 'v1/jhatka/partner/inventory/receipts';
  static const String rejectionReasons =
      'v1/jhatka/partner/inventory/rejection-reasons';
  static const String receiptAccept =
      'v1/jhatka/partner/inventory/receipts/{receipt}/accept';
  static const String receiptReject =
      'v1/jhatka/partner/inventory/receipts/{receipt}/reject';
  static const String receiptPost =
      'v1/jhatka/partner/inventory/receipts/{receipt}/post';

  //// Inventory ////
  static const String inventory = 'v1/jhatka/partner/inventory';
  static const String inventoryItem = 'v1/jhatka/partner/inventory/{id}';
  static const String inventoryMovements =
      'v1/jhatka/partner/inventory/movements';
  static const String batches = 'v1/jhatka/partner/inventory/batches';
  static const String batchQuarantine =
      'v1/jhatka/partner/inventory/batches/{batch}/quarantine';
  static const String batchRelease =
      'v1/jhatka/partner/inventory/batches/{batch}/release';

  //// Recalls — a quarantined batch that must not sell. Opened from the batch,
  /// closed when the fan-out is done. No app-side recall means a food-safety
  /// event handled by phone call instead of by batch lookup.
  static const String recalls = 'v1/jhatka/partner/inventory/recalls';
  static const String recallClose =
      'v1/jhatka/partner/inventory/recalls/{recall}/close';

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
}
