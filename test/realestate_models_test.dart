/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/modules/realestate/models/commission.dart';
import 'package:partner/app/modules/realestate/models/follow_up.dart';
import 'package:partner/app/modules/realestate/models/hold.dart';
import 'package:partner/app/modules/realestate/models/interest.dart';
import 'package:partner/app/modules/realestate/models/lead.dart';
import 'package:partner/app/modules/realestate/models/listing_entitlement.dart';
import 'package:partner/app/modules/realestate/models/listing_order.dart';
import 'package:partner/app/modules/realestate/models/listing_package.dart';
import 'package:partner/app/modules/realestate/models/loan.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/models/property_category.dart';
import 'package:partner/app/modules/realestate/models/property_document.dart';
import 'package:partner/app/modules/realestate/models/sale.dart';
import 'package:partner/app/modules/realestate/models/settlement.dart';
import 'package:partner/app/modules/realestate/models/visit.dart';
import 'package:partner/app/modules/realestate/models/visit_request.dart';

/// Client-side mirror of the money-edges gate: every money field parses
/// in rupees with no conversion. If an edge ever ships paise again, the
/// backend gate goes red first — these tests pin the client assumption.
void main() {
  group('real estate models read rupees, never paise', () {
    test('property price passes through', () {
      final RealEstatePropertyModel m = RealEstatePropertyModel.fromJson(
        <String, dynamic>{
          '_id': 'p1',
          'price': 5000000,
          'location': {
            'coordinates': <double>[78.4, 17.4],
          },
        },
      );
      expect(m.id, 'p1');
      expect(m.price, 5000000);
      expect(m.longitude, 78.4);
      expect(m.latitude, 17.4);
    });

    test('paginated rows parse with id instead of _id', () {
      final RealEstatePropertyModel m = RealEstatePropertyModel.fromJson(
        <String, dynamic>{'id': 'p2', 'price': 5000000},
      );
      expect(m.id, 'p2');
      expect(m.price, 5000000);
      expect(m.createdAt, isNull);
    });

    test('hold triple passes through', () {
      final RealEstateHoldModel m =
          RealEstateHoldModel.fromJson(<String, dynamic>{
            '_id': 'h1',
            'principal': 50000,
            'serviceFee': 2500,
            'total': 52500,
            'status': 'ACTIVE',
          });
      expect(m.principal, 50000);
      expect(m.serviceFee, 2500);
      expect(m.total, 52500);
    });

    test('sale value passes through', () {
      final RealEstateSaleModel m = RealEstateSaleModel.fromJson(
        <String, dynamic>{
          '_id': 's1',
          'saleValue': 5200000,
          'holdPrincipalApplied': 50000,
        },
      );
      expect(m.saleValue, 5200000);
      expect(m.holdPrincipalApplied, 50000);
    });

    test('commission amount and base pass through', () {
      final RealEstateCommissionModel m = RealEstateCommissionModel.fromJson(
        <String, dynamic>{
          '_id': 'c1',
          'baseAmount': 5200000,
          'rate': 2,
          'amount': 104000,
        },
      );
      expect(m.baseAmount, 5200000);
      expect(m.amount, 104000);
      expect(m.rate, 2);
    });

    test('order amount passes through', () {
      final RealEstateOrderModel m = RealEstateOrderModel.fromJson(
        <String, dynamic>{
          '_id': 'o1',
          'amount': 49990,
          'status': 'PENDING_PAYMENT',
        },
      );
      expect(m.amount, 49990);
    });

    test('pay handoff carries the order and payLink', () {
      final RealEstateOrderPayment m = RealEstateOrderPayment.fromJson(
        <String, dynamic>{
          'data': <String, dynamic>{
            '_id': 'o1',
            'amount': 49990,
            'status': 'PENDING_PAYMENT',
          },
          'payLink': 'init1',
        },
      );
      expect(m.payLink, 'init1');
      expect(m.order?.id, 'o1');
      expect(m.order?.amount, 49990);
    });

    test('package price passes through', () {
      final RealEstatePackageModel m = RealEstatePackageModel.fromJson(
        <String, dynamic>{'_id': 'pkg1', 'price': 49990, 'listingCount': 10},
      );
      expect(m.price, 49990);
      expect(m.listingCount, 10);
    });
  });

  group('nested projections parse', () {
    test('lead carries populated customer and property', () {
      final RealEstateLeadModel m = RealEstateLeadModel.fromJson(
        <String, dynamic>{
          '_id': 'l1',
          'leadCode': 'LD-1',
          'status': 'NEW',
          'customer': <String, dynamic>{
            '_id': 'u1',
            'firstName': 'Asha',
            'lastName': 'K',
            'mobile': '9000000001',
          },
          'property': <String, dynamic>{'_id': 'p1', 'title': 'Gate Flat'},
        },
      );
      expect(m.customerId, 'u1');
      expect(m.customer?.displayName, 'Asha K');
      expect(m.propertyId, 'p1');
      expect(m.property?.title, 'Gate Flat');
    });

    test('raw id refs still parse when unpopulated', () {
      final RealEstateLeadModel m = RealEstateLeadModel.fromJson(
        <String, dynamic>{
          '_id': 'l2',
          'customer': 'u2',
          'property': 'p2',
          'vendor': 'v1',
        },
      );
      expect(m.customerId, 'u2');
      expect(m.customer, isNull);
      expect(m.propertyId, 'p2');
      expect(m.property, isNull);
      expect(m.vendorId, 'v1');
    });

    test('lead detail carries activities', () {
      final RealEstateLeadModel m = RealEstateLeadModel.fromJson(
        <String, dynamic>{
          '_id': 'l3',
          'activities': <dynamic>[
            <String, dynamic>{
              '_id': 'a1',
              'action': 'CREATED',
              'toStatus': 'NEW',
            },
          ],
        },
      );
      expect(m.activities.length, 1);
      expect(m.activities.first.action, 'CREATED');
    });

    test('visit request carries populated property price in rupees', () {
      final RealEstateVisitRequestModel m =
          RealEstateVisitRequestModel.fromJson(<String, dynamic>{
            '_id': 'vr1',
            'status': 'PENDING_ASSIGNMENT',
            'property': <String, dynamic>{
              '_id': 'p1',
              'title': 'Gate Flat',
              'price': 5000000,
            },
            'lead': <String, dynamic>{
              '_id': 'l1',
              'leadCode': 'LD-1',
              'status': 'NEW',
            },
          });
      expect(m.property?.price, 5000000);
      expect(m.lead?.leadCode, 'LD-1');
    });

    test('visit carries check-in map and contact refs', () {
      final RealEstateVisitModel m = RealEstateVisitModel.fromJson(
        <String, dynamic>{
          '_id': 'v1',
          'status': 'ASSIGNED',
          'checkInRadiusMeters': 200,
          'customer': <String, dynamic>{'_id': 'u1', 'mobile': '9000000001'},
        },
      );
      expect(m.status, 'ASSIGNED');
      expect(m.checkInRadiusMeters, 200);
      expect(m.customer?.displayName, '9000000001');
    });
  });

  group('remaining wire shapes parse', () {
    test('category keeps spec schema and amenity vocabulary', () {
      final RealEstateCategoryModel m = RealEstateCategoryModel.fromJson(
        <String, dynamic>{
          '_id': 'cat1',
          'key': 'APARTMENT',
          'name': 'Apartment',
          'specSchema': <String, dynamic>{'fields': <dynamic>[]},
          'amenityOptions': <String>['LIFT', 'GYM'],
        },
      );
      expect(m.key, 'APARTMENT');
      expect(m.amenityOptions, <String>['LIFT', 'GYM']);
      expect(m.specSchema, isNotNull);
    });

    test('document parses verification fields', () {
      final RealEstateDocumentModel m =
          RealEstateDocumentModel.fromJson(<String, dynamic>{
            '_id': 'd1',
            'category': 'OWNERSHIP',
            'visibility': 'INTERNAL',
            'status': 'PENDING',
            'title': 'Sale deed',
          });
      expect(m.category, 'OWNERSHIP');
      expect(m.status, 'PENDING');
    });

    test('interest keeps closed level and reason', () {
      final RealEstateInterestModel m = RealEstateInterestModel.fromJson(
        <String, dynamic>{
          '_id': 'i1',
          'level': 'VERY_INTERESTED',
          'reason': 'PRICE',
        },
      );
      expect(m.level, 'VERY_INTERESTED');
      expect(m.reason, 'PRICE');
    });

    test('follow-up keeps mode and schedule', () {
      final RealEstateFollowUpModel m =
          RealEstateFollowUpModel.fromJson(<String, dynamic>{
            '_id': 'f1',
            'status': 'PENDING',
            'mode': 'CALL',
            'nextFollowUpAt': '2026-10-20T10:00:00.000Z',
          });
      expect(m.mode, 'CALL');
      expect(m.nextFollowUpAt?.year, 2026);
    });

    test('entitlement keeps counts', () {
      final RealEstateEntitlementModel m = RealEstateEntitlementModel.fromJson(
        <String, dynamic>{
          '_id': 'e1',
          'totalCount': 10,
          'consumedCount': 3,
          'status': 'ACTIVE',
        },
      );
      expect(m.totalCount, 10);
      expect(m.consumedCount, 3);
    });
  });

  group('executive earnings models', () {
    test('loan parses applications, populated bank and offers', () {
      final RealEstateLoanModel m = RealEstateLoanModel.fromJson(
        <String, dynamic>{
          '_id': 'loan1',
          'requestedAmount': 4500000,
          'tenureMonths': 240,
          'employment': 'SALARIED',
          'monthlyIncome': 150000,
          'status': 'SANCTIONED',
          'customer': <String, dynamic>{
            '_id': 'u1',
            'firstName': 'Asha',
            'lastName': 'K',
          },
          'property': <String, dynamic>{'_id': 'p1', 'title': 'Gate Flat'},
          'applications': <dynamic>[
            <String, dynamic>{
              '_id': 'app1',
              'bank': <String, dynamic>{'_id': 'b1', 'name': 'HDFC'},
              'requestedAmount': 4500000,
              'sanctionedAmount': 4400000,
              'status': 'SANCTIONED',
              'offers': <dynamic>[
                <String, dynamic>{
                  '_id': 'o1',
                  'loanAmount': 4400000,
                  'tenureMonths': 240,
                },
              ],
            },
          ],
        },
      );
      expect(m.customer?.displayName, 'Asha K');
      expect(m.property?.title, 'Gate Flat');
      expect(m.applications.single.bank?.displayName, 'HDFC');
      expect(m.applications.single.offers.single.loanAmount, 4400000);
    });

    test('loan application accepts an unpopulated bank ref', () {
      final RealEstateLoanApplicationModel m =
          RealEstateLoanApplicationModel.fromJson(<String, dynamic>{
            '_id': 'app2',
            'bank': 'b2',
          });
      expect(m.bank?.id, 'b2');
      expect(m.bank?.displayName, 'b2');
    });

    test('settlement reads money from totals', () {
      final RealEstateSettlementModel m = RealEstateSettlementModel.fromJson(
        <String, dynamic>{
          '_id': 'st1',
          'settlementNo': 'ST-1',
          'periodFrom': '2026-10-01T00:00:00.000Z',
          'periodTo': '2026-10-31T00:00:00.000Z',
          'totals': <String, dynamic>{
            'gross': 104000,
            'tds': 1040,
            'net': 102960,
          },
          'status': 'PAID',
        },
      );
      expect(m.gross, 104000);
      expect(m.tds, 1040);
      expect(m.net, 102960);
      expect(m.periodFrom?.month, 10);
    });
  });
}
