/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Â© 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 */

import 'dart:convert';

import 'package:partner/app/core/config/api_endpoints.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/config/payment_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decodeBody', () {
    DioApiResponse ok(String body) =>
        DioApiResponse(body: body, statusCode: 200, errorType: NetErrorType.none);

    test('parses the JSON object the API actually returns', () {
      final Map<String, dynamic> decoded = decodeBody(
        ok(jsonEncode(<String, dynamic>{
          'subscriptions': <dynamic>[
            <String, dynamic>{'id': 's1', 'status': 'active'},
          ],
        })),
      );

      expect(decoded['subscriptions'], isA<List<dynamic>>());
      expect((decoded['subscriptions'] as List<dynamic>).length, 1);
    });

    test('a JSON array is not a response envelope', () {
      // `decodeBody` returns an empty map rather than a List, so a caller doing
      // `body['skus']` cannot blow up on an unexpected top-level shape.
      expect(decodeBody(ok('[1,2,3]')), isEmpty);
    });

    test('an empty or null body is an empty map, not a crash', () {
      expect(decodeBody(ok('')), isEmpty);
      expect(decodeBody(const DioApiResponse()), isEmpty);
    });

    test('malformed JSON yields an empty map rather than throwing', () {
      // The point of the helper: a screen showing "unavailable" beats a
      // FormatError escaping into the widget tree.
      expect(decodeBody(ok('{not json')), isEmpty);
    });

    test('an error response carries no body to decode', () {
      expect(decodeBody(const DioApiResponse.error(NetErrorType.notFound)), isEmpty);
    });
  });

  group('DairyPartnerEndpoints.resolve', () {
    test('outlet-scoped partner paths carry no outlet placeholder', () {
      // These endpoints read the outlet from the token. A `{id}` left in one of
      // them would put the outlet back in the client's hands.
      const List<String> tokenScoped = <String>[
        DairyPartnerEndpoints.partnerDashboard,
        DairyPartnerEndpoints.partnerInventoryList,
        DairyPartnerEndpoints.partnerOrderList,
        DairyPartnerEndpoints.partnerOrderSummary,
        DairyPartnerEndpoints.partnerRunList,
        DairyPartnerEndpoints.partnerRunCreate,
        DairyPartnerEndpoints.partnerSubscriptionList,
        DairyPartnerEndpoints.partnerCustomerList,
        DairyPartnerEndpoints.partnerDriverList,
        DairyPartnerEndpoints.partnerEarnings,
        DairyPartnerEndpoints.partnerSettlements,
        DairyPartnerEndpoints.partnerCanList,
        DairyPartnerEndpoints.partnerProviderCreate,
        DairyPartnerEndpoints.partnerCollectionList,
        DairyPartnerEndpoints.partnerBatchList,
      ];

      for (final String endpoint in tokenScoped) {
        expect(
          endpoint.contains('{id}'),
          isFalse,
          reason: '$endpoint must not carry an outlet id; the server reads it from the token',
        );
      }
    });

    test('resource paths still take their own id', () {
      expect(
        DairyPartnerEndpoints.resolve(
          DairyPartnerEndpoints.partnerProductUpdate,
          <String, String>{'id': 'p1'},
        ),
        endsWith('/products/p1'),
      );
      expect(
        DairyPartnerEndpoints.resolve(
          DairyPartnerEndpoints.partnerInventoryUpdate,
          <String, String>{'id': 'sku1'},
        ),
        endsWith('/skus/sku1/stock'),
      );
    });

    test('subscription pause and resume address one plan', () {
      expect(
        DairyPartnerEndpoints.resolve(
          DairyPartnerEndpoints.partnerSubscriptionPause,
          <String, String>{'subscription': 'sub1'},
        ),
        endsWith('/subscriptions/sub1/pause'),
      );
      expect(
        DairyPartnerEndpoints.resolve(
          DairyPartnerEndpoints.partnerSubscriptionResume,
          <String, String>{'subscription': 'sub1'},
        ),
        endsWith('/subscriptions/sub1/resume'),
      );
    });
  });

  group('PaymentEndpoints.resolve', () {
    test('gateway handoff routes are platform-wide, not vertical-owned', () {
      expect(
        PaymentEndpoints.resolve(
          PaymentEndpoints.makePayment,
          <String, String>{'id': 'pay-1'},
        ),
        'v1/public/payments/makePayment/pay-1',
      );
      expect(
        PaymentEndpoints.resolve(
          PaymentEndpoints.verifyPayment,
          <String, String>{'id': 'pay-1'},
        ),
        'v1/public/payments/paid_success/pay-1',
      );
    });
  });
}
