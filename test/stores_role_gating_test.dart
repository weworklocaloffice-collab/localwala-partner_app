/*
 * WeWorkLocal
 * Hyperlocal Commerce & Service Platform
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 *
 * Unauthorized copying, redistribution, resale, publication,
 * modification, or use of this source code in any public or
 * commercial repository is strictly prohibited.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/modules/stores/partner/more/stores_partner_more_screen.dart';
import 'package:partner/app/modules/stores/partner/orders/stores_order_detail_screen.dart';
import 'package:partner/app/modules/stores/stores_partner_repository.dart';
import 'package:partner/app/modules/stores/stores_permissions.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

/// The DOD's app-side proof (plan 17.5): a dispatcher cannot accept an order,
/// and a non-owner cannot see the money entries.
///
/// The API is the authority in both cases; these tests pin the advisory UI so a
/// limited role never sees an action that the server would refuse.
void main() {
  const StoresPermissions dispatcher = StoresPermissions(<String>[
    'ready_orders.*',
    'drivers.*',
    'assign_driver',
    'delivery.*',
  ]);
  const StoresPermissions manager = StoresPermissions(<String>[
    'orders.*',
    'catalogue.*',
    'inventory.*',
    'delivery.*',
    'promotions.*',
    'returns.*',
    'staff.read',
    'analytics.read',
  ]);

  Future<void> pumpDetail(
    WidgetTester tester, {
    required StoresPermissions permissions,
    required Map<String, dynamic> order,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StoresOrderDetailScreen(
          orderId: 'order-000001',
          permissions: permissions,
          repository: _FakeOrderRepository(order),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpMore(
    WidgetTester tester,
    StoresPermissions permissions,
  ) async {
    tester.view.physicalSize = const Size(800, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StoresPartnerMoreScreen(
          accountScreen: const SizedBox.shrink(),
          permissions: permissions,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('dispatcher sees no accept, reject or cancel', (
    WidgetTester tester,
  ) async {
    await pumpDetail(
      tester,
      permissions: dispatcher,
      order: <String, dynamic>{
        'lifecycle': 'created',
        'paymentMode': 'cod',
        'paymentStatus': 'pending',
      },
    );

    expect(find.text('Accept order'), findsNothing);
    expect(find.text('Reject'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('manager sees the order lifecycle actions', (
    WidgetTester tester,
  ) async {
    await pumpDetail(
      tester,
      permissions: manager,
      order: <String, dynamic>{
        'lifecycle': 'created',
        'paymentMode': 'cod',
        'paymentStatus': 'pending',
      },
    );

    expect(find.text('Accept order'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('assign driver is dispatcher-only, even on a ready order', (
    WidgetTester tester,
  ) async {
    await pumpDetail(
      tester,
      permissions: dispatcher,
      order: <String, dynamic>{'lifecycle': 'ready'},
    );
    expect(find.text('Assign driver'), findsOneWidget);

    await pumpDetail(
      tester,
      permissions: manager,
      order: <String, dynamic>{'lifecycle': 'ready'},
    );
    expect(find.text('Assign driver'), findsNothing);
  });

  testWidgets('non-owners cannot see payments, settlements or subscription', (
    WidgetTester tester,
  ) async {
    await pumpMore(tester, manager);

    expect(find.text('Payments'), findsNothing);
    expect(find.text('Settlements'), findsNothing);
    expect(find.text('Subscription'), findsNothing);
    expect(find.text('Stock'), findsWidgets);
  });

  testWidgets('the owner keeps the money entries', (WidgetTester tester) async {
    await pumpMore(tester, const StoresPermissions(<String>['*']));

    expect(find.text('Payments'), findsOneWidget);
    expect(find.text('Settlements'), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);
  });
}

class _FakeOrderRepository extends StoresPartnerRepository {
  _FakeOrderRepository(this.orderBody);

  final Map<String, dynamic> orderBody;

  @override
  Future<Map<String, dynamic>> order(String orderId) async =>
      <String, dynamic>{'order': orderBody};

  @override
  Future<Map<String, dynamic>> pickList(String orderId) async =>
      <String, dynamic>{'pickList': <Map<String, dynamic>>[]};
}
