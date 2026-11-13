import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/modules/dairy/partner/partner_marketing_view.dart';

class _MarketingRepository extends PartnerRepository {
  bool reportRequested = false;

  DioApiResponse _response(Map<String, dynamic> body) => DioApiResponse.success(jsonEncode(body));

  @override
  Future<DioApiResponse> marketingPackages() async => _response(<String, dynamic>{'packages': <dynamic>[]});

  @override
  Future<DioApiResponse> marketingCampaigns() async => _response(<String, dynamic>{'campaigns': <dynamic>[]});

  @override
  Future<DioApiResponse> coverage() async => _response(<String, dynamic>{'activeLocalities': <dynamic>[]});

  @override
  Future<DioApiResponse> products({int page = 1, int limit = ApiRequestService.pageSize}) async =>
      _response(<String, dynamic>{'products': <dynamic>[]});

  @override
  Future<DioApiResponse> marketingCoupons() async => _response(<String, dynamic>{
        'coupons': <Map<String, dynamic>>[
          <String, dynamic>{
            '_id': 'coupon-1',
            'code': 'MILK10',
            'title': 'Milk offer',
            'discountType': 'fixed',
            'discountValue': 10,
            'status': 'active',
            'redeemedCount': 2,
          },
        ],
      });

  @override
  Future<DioApiResponse> marketingCouponReport(
    String couponId, {
    required DateTime from,
    required DateTime to,
  }) async {
    reportRequested = couponId == 'coupon-1' && to.isAfter(from);
    return _response(<String, dynamic>{
      'report': <String, dynamic>{
        'coupon': <String, dynamic>{'code': 'MILK10', 'title': 'Milk offer'},
        'period': <String, dynamic>{'timezone': 'Asia/Kolkata'},
        'summary': <String, dynamic>{
          'redemptions': 2,
          'discountAmount': 12.5,
          'averageDiscount': 6.25,
          'reservedCount': 1,
          'releasedCount': 1,
          'cancelledAfterRedemptionCount': 0,
        },
        'settlementImpact': <String, dynamic>{
          'basis': 'Delivered and paid orders',
          'orders': 1,
          'grossItemSales': 100,
          'couponDiscount': 12.5,
          'netItemSalesAfterCoupon': 87.5,
          'note': 'Before fees',
        },
        'daily': <Map<String, dynamic>>[
          <String, dynamic>{'date': '2026-11-05', 'redemptions': 2, 'discountAmount': 12.5},
        ],
      },
    });
  }
}

void main() {
  testWidgets('partner can open a coupon redemption report', (WidgetTester tester) async {
    final _MarketingRepository repository = _MarketingRepository();
    await tester.pumpWidget(MaterialApp(home: PartnerMarketingScreen(repository: repository)));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byTooltip('View redemption report'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byTooltip('View redemption report'));
    await tester.pumpAndSettle();

    expect(repository.reportRequested, isTrue);
    expect(find.text('Settlement eligible sales'), findsOneWidget);
    expect(find.text('Sales after coupon'), findsOneWidget);
    expect(find.textContaining('Coupon report'), findsOneWidget);
    expect(find.text('₹87.50'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Daily redemptions'),
      260,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Daily redemptions'), findsOneWidget);
    expect(find.text('2026-11-05'), findsOneWidget);
    expect(find.text('₹12.50'), findsWidgets);
  });
}
