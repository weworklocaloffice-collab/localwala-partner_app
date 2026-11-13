import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/modules/dairy/partner/subscription_list/partner_subscription_list_view.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class _SubscriptionsRepository extends PartnerRepository {
  final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[
    <String, dynamic>{
      '_id': 'subscription-1',
      'status': 'active',
      'user': <String, dynamic>{'firstName': 'Asha', 'lastName': 'Kumar'},
      'sku': <String, dynamic>{
        'name': 'Farm Milk 500 ml',
        'packSize': <String, dynamic>{'value': 500, 'unit': 'ml'},
      },
      'scheduleType': 'daily',
      'quantity': 1,
    },
    <String, dynamic>{
      '_id': 'subscription-2',
      'status': 'paused',
      'user': <String, dynamic>{'firstName': 'Ravi', 'lastName': 'Shah'},
      'sku': <String, dynamic>{
        'name': 'Curd 1 kg',
        'packSize': <String, dynamic>{'value': 1, 'unit': 'kg'},
      },
      'scheduleType': 'weekly',
      'quantity': 2,
    },
  ];

  @override
  Future<DioApiResponse> subscriptions({
    int page = 1,
    int limit = ApiRequestService.pageSize,
  }) async => DioApiResponse.success(
    jsonEncode(<String, dynamic>{'subscriptions': rows}),
  );
}

void main() {
  testWidgets('partner can search and filter subscriptions', (
    WidgetTester tester,
  ) async {
    final _SubscriptionsRepository repository = _SubscriptionsRepository();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PartnerSubscriptionListScreen(partnerRepository: repository),
      ),
    );
    await tester.pumpAndSettle();

    final Finder search = find.byKey(
      const ValueKey<String>('dairy-subscriptions-search'),
    );
    await tester.enterText(search, 'Ravi');
    await tester.pumpAndSettle();
    expect(find.text('Ravi Shah'), findsOneWidget);
    expect(find.text('Asha Kumar'), findsNothing);

    await tester.enterText(search, '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Active · 1'));
    await tester.pumpAndSettle();
    expect(find.text('Asha Kumar'), findsOneWidget);
    expect(find.text('Ravi Shah'), findsNothing);
  });
}
