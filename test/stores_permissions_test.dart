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

import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/modules/stores/stores_permissions.dart';

/// The app-side matcher must agree with the server's `can()` (§6.23).
///
/// These are the exact role lists from `stores.profile.service.js`. If a role gains
/// or loses a right on the server, this file should change with it — the UI gating it
/// drives is advisory, but a mismatch makes the app offer buttons the server refuses
/// or hide ones the role is allowed to use.
void main() {
  group('matcher', () {
    test('exact right', () {
      expect(const StoresPermissions(<String>['orders.write']).can('orders.write'), isTrue);
    });

    test('head wildcard covers every verb under it', () {
      const StoresPermissions manager = StoresPermissions(<String>['orders.*']);
      expect(manager.can('orders.read'), isTrue);
      expect(manager.can('orders.write'), isTrue);
      expect(manager.can('delivery.assign_driver'), isFalse);
    });

    test('capability word grants the namespaced right', () {
      expect(
        const StoresPermissions(<String>['assign_driver']).can('delivery.assign_driver'),
        isTrue,
      );
    });

    test('owner wildcard grants owner-only money rights', () {
      expect(
        const StoresPermissions(<String>['*']).can('settlement.view'),
        isTrue,
      );
    });
  });

  group('server role lists', () {
    test('manager runs orders and delivery but not settlements or subscription', () {
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
      expect(manager.can('orders.write'), isTrue);
      expect(manager.can('delivery.assign_driver'), isTrue);
      expect(manager.can('settlement.view'), isFalse);
      expect(manager.can('subscription.manage'), isFalse);
      expect(manager.can('costprice.view'), isFalse);
    });

    test('dispatcher cannot manage an order but can dispatch from ready', () {
      const StoresPermissions dispatcher = StoresPermissions(<String>[
        'ready_orders.*',
        'drivers.*',
        'assign_driver',
        'delivery.*',
      ]);
      expect(dispatcher.can('orders.write'), isFalse);
      expect(dispatcher.can('ready_orders.read'), isTrue);
      expect(dispatcher.can('delivery.assign_driver'), isTrue);
    });

    test('order manager packs and cancels but does not assign a driver', () {
      const StoresPermissions orderManager = StoresPermissions(<String>[
        'orders.*',
        'picking.*',
        'packing.*',
        'cancellations.*',
        'returns.read',
        'customers.read',
      ]);
      expect(orderManager.can('orders.write'), isTrue);
      expect(orderManager.can('delivery.assign_driver'), isFalse);
      expect(orderManager.can('settlement.view'), isFalse);
    });

    test('inventory manager adjusts stock but cannot price or see cost', () {
      const StoresPermissions inventoryManager = StoresPermissions(<String>[
        'catalogue.*',
        'inventory.*',
        'stock_adjust',
        'stock_movements',
      ]);
      expect(inventoryManager.can('inventory.stock_adjust'), isTrue);
      expect(inventoryManager.can('catalogue.write'), isTrue);
      expect(inventoryManager.can('costprice.view'), isFalse);
      expect(inventoryManager.can('orders.write'), isFalse);
    });
  });

  group('payload', () {
    test('parses the capabilities permissions list', () {
      final StoresPermissions parsed = StoresPermissions.fromCapabilities(
        <String, dynamic>{
          'permissions': <String>['orders.*', 'delivery.*'],
        },
      );
      expect(parsed.can('orders.write'), isTrue);
      expect(parsed.can('settlement.view'), isFalse);
    });

    test('a payload without permissions stays unrestricted', () {
      expect(
        StoresPermissions.fromCapabilities(const <String, dynamic>{})
            .can('settlement.view'),
        isTrue,
      );
    });
  });
}
