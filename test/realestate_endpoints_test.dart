/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/core/config/realestate_endpoints.dart';

void main() {
  group('RealEstateEndpoints', () {
    test('vendor paths live under v1/realestate/vendor', () {
      for (final String p in <String>[
        RealEstateEndpoints.vendorRegister,
        RealEstateEndpoints.vendorMe,
        RealEstateEndpoints.vendorDashboard,
        RealEstateEndpoints.vendorPackages,
        RealEstateEndpoints.vendorOrders,
        RealEstateEndpoints.vendorOrderPay,
        RealEstateEndpoints.vendorEntitlements,
        RealEstateEndpoints.vendorProperties,
        RealEstateEndpoints.vendorLeads,
        RealEstateEndpoints.vendorVisits,
        RealEstateEndpoints.vendorHolds,
        RealEstateEndpoints.vendorCustomers,
        RealEstateEndpoints.vendorAnalytics,
        RealEstateEndpoints.vendorCommissions,
        RealEstateEndpoints.vendorSales,
      ]) {
        expect(p.startsWith('v1/realestate/vendor/'), isTrue, reason: p);
      }
    });

    test('shared payment handoff lives under public payments', () {
      expect(
        RealEstateEndpoints.paymentMake.startsWith('v1/public/payments/'),
        isTrue,
      );
      expect(
        RealEstateEndpoints.paymentSuccess.startsWith('v1/public/payments/'),
        isTrue,
      );
    });

    test('executive paths live under v1/realestate/executive', () {
      for (final String p in <String>[
        RealEstateEndpoints.executiveMe,
        RealEstateEndpoints.executiveDashboard,
        RealEstateEndpoints.executiveLocation,
        RealEstateEndpoints.executiveVisits,
        RealEstateEndpoints.executiveVisitCheckIn,
        RealEstateEndpoints.executiveVisitInterest,
        RealEstateEndpoints.executiveLeads,
        RealEstateEndpoints.executiveProperty,
        RealEstateEndpoints.executiveFollowUps,
        RealEstateEndpoints.executiveCommissions,
        RealEstateEndpoints.executiveHolds,
        RealEstateEndpoints.executiveHold,
        RealEstateEndpoints.executiveLoans,
        RealEstateEndpoints.executiveLoan,
        RealEstateEndpoints.executiveSales,
        RealEstateEndpoints.executiveSale,
        RealEstateEndpoints.executiveSettlements,
        RealEstateEndpoints.executiveNotifications,
        RealEstateEndpoints.executiveNotificationRead,
      ]) {
        expect(p.startsWith('v1/realestate/executive/'), isTrue, reason: p);
      }
    });

    test('no template names an actor id (doc 7.1)', () {
      for (final String p in <String>[
        RealEstateEndpoints.vendorProperties,
        RealEstateEndpoints.vendorProperty,
        RealEstateEndpoints.vendorLeads,
        RealEstateEndpoints.vendorVisits,
        RealEstateEndpoints.vendorHolds,
        RealEstateEndpoints.vendorCustomers,
        RealEstateEndpoints.vendorCommissions,
        RealEstateEndpoints.vendorSales,
        RealEstateEndpoints.executiveVisits,
        RealEstateEndpoints.executiveLeads,
        RealEstateEndpoints.executiveProperty,
      ]) {
        expect(p.contains('{vendorId}'), isFalse, reason: p);
        expect(p.contains('{executiveId}'), isFalse, reason: p);
        expect(p.contains('{customerId}'), isFalse, reason: p);
      }
    });

    test('resolve fills resource placeholders', () {
      expect(
        RealEstateEndpoints.resolve(
          RealEstateEndpoints.vendorPropertyStatus,
          <String, String>{'id': 'abc123', 'status': 'SUBMITTED'},
        ),
        'v1/realestate/vendor/properties/abc123/status/SUBMITTED',
      );
      expect(
        RealEstateEndpoints.resolve(
          RealEstateEndpoints.executiveLeadFollowUps,
          <String, String>{'leadId': 'lead9'},
        ),
        'v1/realestate/executive/leads/lead9/followups',
      );
    });

    test(
      'resolve throws on a missing value instead of shipping {id} in the URL',
      () {
        expect(
          () => RealEstateEndpoints.resolve(
            RealEstateEndpoints.vendorOrder,
            <String, String>{},
          ),
          throwsArgumentError,
        );
      },
    );
  });
}
