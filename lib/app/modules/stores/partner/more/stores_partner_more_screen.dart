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

import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:partner/app/modules/stores/partner/inventory/stores_inventory_screen.dart';
import 'package:partner/app/modules/stores/partner/manual/stores_manual_order_screen.dart';
import 'package:partner/app/modules/stores/partner/dispatch/stores_partner_dispatch_screen.dart';
import 'package:partner/app/modules/stores/partner/delivery/stores_partner_delivery_tracking_screen.dart';
import 'package:partner/app/modules/stores/partner/exchanges/stores_partner_exchanges_screen.dart';
import 'package:partner/app/modules/stores/partner/returns/stores_partner_returns_screen.dart';
import 'package:partner/app/modules/stores/partner/settings/stores_partner_settings_screen.dart';
import 'package:partner/app/modules/stores/partner/marketing/stores_featured_screen.dart';
import 'package:partner/app/modules/stores/partner/money/stores_payments_screen.dart';
import 'package:partner/app/modules/stores/partner/postsale/stores_postsale_screen.dart';
import 'package:partner/app/modules/stores/partner/analytics/stores_partner_analytics_screen.dart';
import 'package:partner/app/modules/stores/partner/categories/stores_partner_categories_screen.dart';
import 'package:partner/app/modules/stores/partner/customers/stores_partner_customers_screen.dart';
import 'package:partner/app/modules/stores/partner/policies/stores_partner_policies_screen.dart';
import 'package:partner/app/modules/stores/partner/products/stores_partner_products_screen.dart';
import 'package:partner/app/modules/stores/partner/profile/stores_partner_store_profile_screen.dart';
import 'package:partner/app/modules/stores/partner/reviews/stores_partner_reviews_screen.dart';
import 'package:partner/app/modules/stores/partner/promotions/stores_promotions_screen.dart';
import 'package:partner/app/modules/stores/partner/recurring/stores_partner_recurring_plans_screen.dart';
import 'package:partner/app/modules/stores/partner/settlements/stores_settlements_screen.dart';
import 'package:partner/app/modules/stores/partner/staff/stores_team_screen.dart';
import 'package:partner/app/modules/stores/partner/subscriptions/stores_partner_subscriptions_screen.dart';
import 'package:partner/app/modules/stores/partner/subscription/stores_subscription_screen.dart';
import 'package:partner/app/modules/stores/partner/support/stores_complaints_screen.dart';
import 'package:partner/app/modules/stores/partner/warranty/stores_warranty_screen.dart';

/// The grouped `More` list — the fifth tab (plan §10.1).
///
/// Spec §38's partner list would be ~20 bottom destinations; the five-tab shell with a
/// grouped More is the deliberate answer. Every entry pushes an existing screen, so this
/// file holds no behaviour of its own — the screens decide their own loading, scoping and
/// gating, and this list cannot diverge from them.
class StoresPartnerMoreScreen extends StatelessWidget {
  const StoresPartnerMoreScreen({super.key, required this.accountScreen});

  final Widget accountScreen;

  static const List<StoresMoreEntry> entries = <StoresMoreEntry>[
    StoresMoreEntry(icon: Icons.point_of_sale_outlined, keyName: 'manual'),
    StoresMoreEntry(icon: Icons.payments_outlined, keyName: 'payments'),
    StoresMoreEntry(icon: Icons.inventory_2_outlined, keyName: 'inventory'),
    StoresMoreEntry(icon: Icons.inventory_2_outlined, keyName: 'recurringplans'),
    StoresMoreEntry(icon: Icons.assignment_return_outlined, keyName: 'returns'),
    StoresMoreEntry(icon: Icons.swap_horiz_outlined, keyName: 'exchanges'),
    StoresMoreEntry(icon: Icons.local_shipping_outlined, keyName: 'deliverytracking'),
    StoresMoreEntry(icon: Icons.settings_outlined, keyName: 'settings'),
    StoresMoreEntry(icon: Icons.card_membership_outlined, keyName: 'subscription'),
    StoresMoreEntry(icon: Icons.people_outline, keyName: 'customers'),
    StoresMoreEntry(icon: Icons.account_balance_wallet_outlined, keyName: 'settlements'),
    StoresMoreEntry(icon: Icons.local_offer_outlined, keyName: 'promotions'),
    StoresMoreEntry(icon: Icons.storefront_outlined, keyName: 'profile'),
    StoresMoreEntry(icon: Icons.category_outlined, keyName: 'categories'),
    StoresMoreEntry(icon: Icons.inventory_2_outlined, keyName: 'products'),
    StoresMoreEntry(icon: Icons.local_shipping_outlined, keyName: 'dispatch'),
    StoresMoreEntry(icon: Icons.analytics_outlined, keyName: 'analytics'),
    StoresMoreEntry(icon: Icons.policy_outlined, keyName: 'policies'),
    StoresMoreEntry(icon: Icons.rate_review_outlined, keyName: 'reviews'),
    StoresMoreEntry(icon: Icons.verified_outlined, keyName: 'warranty'),
    StoresMoreEntry(icon: Icons.support_agent_outlined, keyName: 'support'),
    StoresMoreEntry(icon: Icons.group_outlined, keyName: 'team'),
    StoresMoreEntry(icon: Icons.person_outline, keyName: 'account'),
  ];

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            ListTile(title: Text(l10n.storesMoney)),
            for (final StoresMoreEntry entry in entries.where((e) =>
                e.keyName == 'manual' ||
                e.keyName == 'payments' ||
                e.keyName == 'settlements'))
              _tile(context, entry),
            ListTile(title: Text(l10n.storesOperations)),
            for (final StoresMoreEntry entry in entries.where((e) =>
                e.keyName == 'inventory' ||
                e.keyName == 'recurringplans' ||
                e.keyName == 'exchanges' ||
                e.keyName == 'returns' ||
                e.keyName == 'deliverytracking' ||
                e.keyName == 'settings' ||
                e.keyName == 'profile' ||
                e.keyName == 'categories' ||
                e.keyName == 'products' ||
                e.keyName == 'dispatch' ||
                e.keyName == 'analytics' ||
                e.keyName == 'policies' ||
                e.keyName == 'reviews' ||
                e.keyName == 'postsale' ||
                e.keyName == 'promotions' ||
                e.keyName == 'featured' ||
                e.keyName == 'warranty'))
              _tile(context, entry),
            ListTile(title: Text(l10n.storesAccount)),
            for (final StoresMoreEntry entry in entries.where((e) =>
                e.keyName == 'subscription' ||
                e.keyName == 'customers' ||
                e.keyName == 'customersubscriptions' ||
                e.keyName == 'support' ||
                e.keyName == 'team' ||
                e.keyName == 'account'))
              _tile(context, entry),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, StoresMoreEntry entry) {
    void push(Widget screen) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => screen),
      );
    }

    switch (entry.keyName) {
      case 'manual':
        return push(const StoresManualOrderScreen());
      case 'payments':
        return push(const StoresPaymentsScreen());
      case 'inventory':
        return push(const StoresInventoryScreen());
      case 'recurringplans':
        return push(const StoresPartnerRecurringPlansScreen());
      case 'postsale':
        return push(const StoresPostSaleScreen());
      case 'exchanges':
        return push(const StoresPartnerExchangesScreen());
      case 'returns':
        return push(const StoresPartnerReturnsScreen());
      case 'deliverytracking':
        return push(const StoresPartnerDeliveryTrackingScreen());
      case 'settings':
        return push(const StoresPartnerSettingsScreen());
      case 'subscription':
        return push(const StoresSubscriptionScreen());
      case 'customersubscriptions':
        return push(const StoresPartnerSubscriptionsScreen());
      case 'customers':
        return push(const StoresPartnerCustomersScreen());
      case 'settlements':
        return push(const StoresSettlementsScreen());
      case 'promotions':
        return push(const StoresPromotionsScreen());
      case 'featured':
        return push(const StoresFeaturedScreen());
      case 'profile':
        return push(const StoresPartnerStoreProfileScreen());
      case 'categories':
        return push(const StoresPartnerCategoriesScreen());
      case 'products':
        return push(const StoresPartnerProductsScreen());
      case 'dispatch':
        return push(const StoresPartnerDispatchScreen());
      case 'analytics':
        return push(const StoresPartnerAnalyticsScreen());
      case 'policies':
        return push(const StoresPartnerPoliciesScreen());
      case 'reviews':
        return push(const StoresPartnerReviewsScreen());
      case 'warranty':
        return push(const StoresWarrantyScreen());
      case 'support':
        return push(const StoresComplaintsScreen());
      case 'team':
        return push(const StoresTeamScreen());
      case 'account':
        return push(accountScreen);
    }
  }

  Widget _tile(BuildContext context, StoresMoreEntry entry) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;

    return ListTile(
      leading: Icon(entry.icon),
      title: Text(_labelFor(l10n, entry.keyName)),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _open(context, entry),
    );
  }

  String _labelFor(AppLocalizations l10n, String keyName) {
    switch (keyName) {
      case 'manual':
        return l10n.storesTitleManualOrder;
      case 'payments':
        return l10n.storesTitlePayments;
      case 'inventory':
        return l10n.storesTitleStock;
      case 'recurringplans':
        return l10n.storesTitleRecurringPlans;
      case 'postsale':
        return l10n.storesTitlePostsale;
      case 'exchanges':
        return l10n.storesTitleExchanges;
      case 'returns':
        return l10n.storesTitleReturns;
      case 'deliverytracking':
        return l10n.storesTitleDeliveryTracking;
      case 'settings':
        return l10n.storesTitleSettings;
      case 'subscription':
        return l10n.storesTitleSubscription;
      case 'customersubscriptions':
        return l10n.storesTitleCustomerSubscriptions;
      case 'customers':
        return l10n.storesTitleCustomers;
      case 'settlements':
        return l10n.storesTabSettlements;
      case 'promotions':
        return l10n.storesTitlePromotions;
      case 'featured':
        return l10n.storesTitleFeatured;
      case 'profile':
        return l10n.storesLabelStoreProfile;
      case 'categories':
        return l10n.storesLabelCategories;
      case 'products':
        return l10n.storesLabelProducts;
      case 'dispatch':
        return l10n.storesLabelDispatch;
      case 'analytics':
        return l10n.storesLabelAnalytics;
      case 'policies':
        return l10n.storesLabelPolicies;
      case 'reviews':
        return l10n.storesLabelReviews;
      case 'warranty':
        return l10n.storesTitleWarranty;
      case 'support':
        return l10n.storesTitleSupport;
      case 'team':
        return l10n.storesTitleTeam;
      case 'account':
        return l10n.storesNavAccount;
      default:
        return keyName;
    }
  }
}

/// One row in the More list.
class StoresMoreEntry {
  const StoresMoreEntry({required this.icon, required this.keyName});

  final IconData icon;

  /// Stable internal key; the label resolves through l10n, never stored here.
  final String keyName;
}
