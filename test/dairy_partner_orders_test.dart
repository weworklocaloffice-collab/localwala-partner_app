import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/modules/dairy/partner/order_list/partner_order_list_view.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class _OrdersRepository extends PartnerRepository {
  final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[
    <String, dynamic>{
      '_id': 'order-1',
      'orderNo': 'DW-101',
      'status': 'confirmed',
      'itemTotal': 100,
      'grandTotal': 105,
    },
    <String, dynamic>{
      '_id': 'order-2',
      'orderNo': 'DW-102',
      'status': 'out_for_delivery',
      'itemTotal': 200,
      'grandTotal': 210,
    },
    <String, dynamic>{
      '_id': 'order-3',
      'orderNo': 'DW-103',
      'status': 'delivered',
      'itemTotal': 300,
      'grandTotal': 315,
    },
  ];

  @override
  Future<DioApiResponse> orders({
    int page = 1,
    int limit = ApiRequestService.pageSize,
    String? status,
  }) async => DioApiResponse.success(jsonEncode(<String, dynamic>{'orders': rows}));
}

void main() {
  testWidgets('partner can search and filter orders', (WidgetTester tester) async {
    final _OrdersRepository repository = _OrdersRepository();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PartnerOrderListScreen(partnerRepository: repository),
      ),
    );
    await tester.pumpAndSettle();

    final Finder search = find.byKey(const ValueKey<String>('dairy-orders-search'));
    await tester.enterText(search, 'DW-101');
    await tester.pumpAndSettle();
    expect(find.text('Order #DW-101'), findsOneWidget);
    expect(find.textContaining('DW-102'), findsNothing);

    await tester.enterText(search, '');
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('In progress · 1'));
    await tester.pumpAndSettle();
    expect(find.text('Order #DW-102'), findsOneWidget);
    expect(find.text('Order #DW-101'), findsNothing);
    expect(find.text('Order #DW-103'), findsNothing);
  });
}
