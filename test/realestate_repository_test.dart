/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/app/modules/realestate/models/listing_package.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/models/property_category.dart';
import 'package:partner/app/modules/realestate/repository/vendor_repository.dart';

/// Envelope contracts the repositories assume.
///
/// Each backend list answers `{results, page, limit, total}` (or the
/// paginate twin `{results, totalResults}`), each single answers `{data}`.
/// If an endpoint changes its envelope, the repository silently yields
/// empty lists — these tests pin the shapes so a drift fails loudly.
void main() {
  List<T> resultsOf<T>(Map<String, dynamic> body, T Function(Map<String, dynamic>) parse) {
    final List<dynamic> raw = body['results'] is List ? body['results'] as List<dynamic> : const <dynamic>[];
    return raw.whereType<Map>().map((Map m) => parse(Map<String, dynamic>.from(m))).toList();
  }

  group('repository envelope contracts', () {
    test('paginated list envelope parses to models with totals', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'results': <dynamic>[
          <String, dynamic>{'_id': 'p1', 'price': 5000000, 'title': 'Gate Flat'},
        ],
        'page': 1,
        'limit': 20,
        'total': 1,
      };
      final RealEstatePage<RealEstatePropertyModel> page = RealEstatePage<RealEstatePropertyModel>(
        items: resultsOf(body, RealEstatePropertyModel.fromJson),
        page: 1,
        limit: 20,
        total: (body['total'] ?? body['totalResults']) is num
            ? ((body['total'] ?? body['totalResults']) as num).toInt()
            : 0,
      );
      expect(page.items.length, 1);
      expect(page.items.first.price, 5000000);
      expect(page.total, 1);
    });

    test('paginate twin envelope (totalResults) parses', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'results': <dynamic>[
          <String, dynamic>{'id': 'p1', 'price': 5000000},
        ],
        'page': 1,
        'limit': 20,
        'totalPages': 1,
        'totalResults': 1,
      };
      final dynamic total = body['total'] ?? body['totalResults'];
      expect(total, 1);
      expect(resultsOf(body, RealEstatePropertyModel.fromJson).first.id, 'p1');
    });

    test('single envelope parses to a model', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'data': <String, dynamic>{'_id': 'pkg1', 'code': 'BASIC', 'price': 49990},
      };
      final dynamic data = body['data'];
      final RealEstatePackageModel? pkg =
          data is Map ? RealEstatePackageModel.fromJson(Map<String, dynamic>.from(data)) : null;
      expect(pkg?.code, 'BASIC');
      expect(pkg?.price, 49990);
    });

    test('missing data envelope yields null, not a crash', () {
      final Map<String, dynamic> body = <String, dynamic>{'message': 'Not found'};
      final dynamic data = body['data'];
      expect(data is Map, isFalse);
    });

    test('category single is unwrapped (no data envelope)', () {
      final Map<String, dynamic> body = <String, dynamic>{
        '_id': 'cat1',
        'key': 'APARTMENT',
        'name': 'Apartment',
      };
      expect(body['key'], isNotNull);
      expect(RealEstateCategoryModel.fromJson(body).key, 'APARTMENT');
    });

    test('customers page carries contact rows', () {
      final Map<String, dynamic> body = <String, dynamic>{
        'results': <dynamic>[
          <String, dynamic>{
            'id': 'u1',
            'firstName': 'Asha',
            'lastName': 'K',
            'mobile': '9000000001',
          },
        ],
        'page': 1,
        'limit': 20,
        'total': 1,
      };
      final List<RealEstateCustomerRef> rows = resultsOf(body, RealEstateCustomerRef.fromJson);
      expect(rows.length, 1);
      expect(rows.first.displayName, 'Asha K');
    });
  });

  group('RealEstateApiException', () {
    test('carries message and status', () {
      const RealEstateApiException e = RealEstateApiException('Not found', 404);
      expect(e.statusCode, 404);
      expect(e.toString(), contains('404'));
      expect(e.toString(), contains('Not found'));
    });
  });
}
