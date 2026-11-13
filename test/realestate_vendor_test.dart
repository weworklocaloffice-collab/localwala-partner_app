/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/modules/realestate/models/lead_detail.dart';
import 'package:partner/app/modules/realestate/models/listing_entitlement.dart';
import 'package:partner/app/modules/realestate/vendor/packages/bloc/vendor_packages_bloc.dart';
import 'package:partner/app/modules/realestate/models/property.dart';
import 'package:partner/app/modules/realestate/vendor/leads/bloc/vendor_leads_bloc.dart';
import 'package:partner/app/modules/realestate/vendor/listings/bloc/vendor_listings_bloc.dart';
import 'package:partner/app/modules/realestate/vendor/listings/detail/bloc/listing_detail_bloc.dart';
import 'package:partner/app/modules/realestate/vendor/nav_config.dart';
import 'package:partner/app/modules/realestate/vendor/visits/bloc/vendor_visits_bloc.dart';
import 'package:partner/app/modules/realestate/vendor/listings/form/bloc/listing_form_bloc.dart';

/// Tab registry contract: nine tabs, stable ids, and the status fan-out
/// each tab queries. The bloc consumes this mapping; the view renders it.
void main() {
  group('listings tabs', () {
    test('nine tabs in blueprint order', () {
      expect(
        listingsTabs.map((ListingsTab t) => t.id).toList(),
        <String>[
          'all',
          'DRAFT',
          'SUBMITTED',
          'IN_REVIEW',
          'CHANGES_REQUIRED',
          'APPROVED',
          'PUBLISHED',
          'SOLD_RENTED',
          'ARCHIVED',
        ],
      );
    });

    test('all tab is unfiltered', () {
      expect(listingsTabStatuses('all'), isNull);
    });

    test('state tabs map to their own status', () {
      expect(listingsTabStatuses('DRAFT'), <String>['DRAFT']);
      expect(listingsTabStatuses('PUBLISHED'), <String>['PUBLISHED']);
    });

    test('sold/rented tab fans out to both closed states', () {
      expect(listingsTabStatuses('SOLD_RENTED'), <String>['SOLD', 'RENTED']);
    });
  });

  group('spec descriptors', () {
    test('parses every field type with label fallback', () {
      final List<SpecFieldDescriptor> fields = specFieldsOf(<String, dynamic>{
        'fields': <dynamic>[
          <String, dynamic>{'key': 'bedrooms', 'type': 'NUMBER', 'required': true, 'integer': true, 'min': 1},
          <String, dynamic>{'key': 'facing', 'type': 'ENUM', 'options': <String>['EAST', 'WEST']},
          <String, dynamic>{'key': 'gated', 'type': 'BOOLEAN'},
          <String, dynamic>{'key': 'possessionDate', 'type': 'DATE'},
          <String, dynamic>{'key': 'notes', 'type': 'TEXT', 'maxLength': 500},
          <String, dynamic>{'key': 'mystery', 'type': 'FUTURE_TYPE'},
        ],
      });

      expect(fields.length, 6);
      expect(fields[0].label, 'Bedrooms');
      expect(fields[0].required, isTrue);
      expect(fields[0].integer, isTrue);
      expect(fields[1].options, <String>['EAST', 'WEST']);
      expect(fields[4].maxLength, 500);
      // Unknown types degrade to text, labels humanize.
      expect(fields[5].type, 'FUTURE_TYPE');
      expect(SpecFieldDescriptor.humanize('possessionStatus'), 'Possession Status');
      expect(SpecFieldDescriptor.humanize('car_parking'), 'Car Parking');
    });

    test('empty schema yields no fields', () {
      expect(specFieldsOf(null), isEmpty);
      expect(specFieldsOf(<String, dynamic>{}), isEmpty);
    });

    test('values validate like the server', () {
      const SpecFieldDescriptor bedrooms = SpecFieldDescriptor(
        key: 'bedrooms',
        label: 'Bedrooms',
        type: 'NUMBER',
        required: true,
        integer: true,
        min: 1,
      );
      expect(validateSpecValue(bedrooms, null), isNotNull);
      expect(validateSpecValue(bedrooms, '3'), isNull);
      expect(validateSpecValue(bedrooms, '1.5'), isNotNull);
      expect(validateSpecValue(bedrooms, '0'), isNotNull);

      const SpecFieldDescriptor facing = SpecFieldDescriptor(
        key: 'facing',
        label: 'Facing',
        type: 'ENUM',
        options: <String>['EAST', 'WEST'],
      );
      expect(validateSpecValue(facing, null), isNull);
      expect(validateSpecValue(facing, 'NORTH'), isNotNull);
      expect(validateSpecValue(facing, 'EAST'), isNull);
    });
  });

  group('listing payload', () {
    Map<String, dynamic> validOver({Map<String, dynamic>? specs}) {
      return buildListingPayload(
        title: 'Gate Villa',
        transactionType: 'BUY',
        price: 5000000,
        priceOnRequest: false,
        categoryId: 'cat1',
        localityId: 'loc1',
        cityId: 'city1',
        lng: 78.4,
        lat: 17.4,
        specs: specs ?? <String, dynamic>{'bedrooms': '3'},
        amenities: <String>['LIFT'],
        mediaUrls: <String>['a.jpg', 'b.jpg'],
      );
    }

    test('exact keys: no state, country, status or vendor', () {
      final Map<String, dynamic> payload = validOver();
      expect(payload.containsKey('state'), isFalse);
      expect(payload.containsKey('country'), isFalse);
      expect(payload.containsKey('status'), isFalse);
      expect(payload.containsKey('vendor'), isFalse);
      expect(payload.containsKey('customer'), isFalse);
      expect(payload['title'], 'Gate Villa');
      expect((payload['location'] as Map)['coordinates'], <double>[78.4, 17.4]);
    });

    test('media carries sort order, empties omitted', () {
      final Map<String, dynamic> payload = validOver();
      final List<dynamic> media = payload['media'] as List<dynamic>;
      expect(media.length, 2);
      expect((media[0] as Map)['sortOrder'], 0);
      expect((media[1] as Map)['url'], 'b.jpg');

      final Map<String, dynamic> bare = buildListingPayload(
        title: 'Gate Villa',
        transactionType: 'RENT',
        price: 20000,
        priceOnRequest: false,
        categoryId: 'cat1',
        localityId: 'loc1',
        cityId: 'city1',
        lng: 78.4,
        lat: 17.4,
      );
      expect(bare.containsKey('media'), isFalse);
      expect(bare.containsKey('specs'), isFalse);
      expect(bare.containsKey('description'), isFalse);
    });

    test('validation catches every missing piece', () {
      String? check(Map<String, dynamic> payload, {List<SpecFieldDescriptor> fields = const <SpecFieldDescriptor>[]}) {
        return validateListingInput(
          title: (payload['title'] ?? '') as String,
          transactionType: (payload['transactionType'] ?? 'BUY') as String,
          price: payload['price'] as double?,
          categoryId: payload['categoryId'] as String?,
          cityId: payload['cityId'] as String?,
          localityId: payload['localityId'] as String?,
          lat: payload['lat'] as double?,
          lng: payload['lng'] as double?,
          specFields: fields,
          specs: const <String, dynamic>{},
          amenities: const <String>[],
          mediaUrls: const <String>[],
        );
      }

      expect(check(<String, dynamic>{'title': 'AB'}), contains('title'));
      expect(
        check(<String, dynamic>{'title': 'Gate Villa', 'transactionType': 'BARTER'}),
        contains('sale or rent'),
      );
      expect(
        check(<String, dynamic>{'title': 'Gate Villa', 'transactionType': 'RENT'}),
        contains('price'),
      );
    });
  });

  group('listing detail actions', () {
    List<String> targets(String? status) =>
        availableDetailActions(status).map((DetailAction a) => a.target).toList();

    test('draft offers submit and withdraw', () {
      expect(targets('DRAFT'), <String>['SUBMITTED', 'ARCHIVED']);
    });

    test('changes-requested offers resubmit and withdraw', () {
      final List<DetailAction> actions = availableDetailActions('CHANGES_REQUIRED');
      expect(actions.map((DetailAction a) => a.target).toList(), <String>['SUBMITTED', 'ARCHIVED']);
      expect(actions.first.kind, DetailActionKind.resubmit);
    });

    test('in-flight listings offer withdraw only', () {
      for (final String status in <String>['SUBMITTED', 'IN_REVIEW', 'APPROVED']) {
        expect(targets(status), <String>['ARCHIVED'], reason: status);
      }
    });

    test('live and closed listings offer archive only', () {
      for (final String status in <String>['PUBLISHED', 'SOLD', 'RENTED', 'SUSPENDED', 'EXPIRED', 'REJECTED']) {
        expect(targets(status), <String>['ARCHIVED'], reason: status);
      }
    });

    test('archived and unknown offer nothing', () {
      expect(targets('ARCHIVED'), isEmpty);
      expect(targets(null), isEmpty);
      expect(targets('SOMETHING_NEW'), isEmpty);
    });

    test('milestones keep only dated moments', () {
      final RealEstatePropertyModel property = RealEstatePropertyModel.fromJson(<String, dynamic>{
        '_id': 'p1',
        'createdAt': '2026-09-01T10:00:00.000Z',
        'submittedAt': '2026-09-02T10:00:00.000Z',
      });
      final List<ListingMilestone> milestones = listingMilestones(property);
      expect(milestones.map((ListingMilestone m) => m.label).toList(), <String>['Created', 'Submitted']);
    });
  });

  group('leads tabs', () {
    test('ten tabs in lifecycle order', () {
      expect(
        leadsTabs.map((LeadsTab t) => t.id).toList(),
        <String>[
          'all',
          'NEW',
          'CONTACTED',
          'VISIT_REQUESTED',
          'VISIT_SCHEDULED',
          'VISIT_COMPLETED',
          'FOLLOW_UP',
          'HOLD',
          'SALE',
          'LOST',
        ],
      );
    });

    test('all tab is unfiltered, states map to themselves', () {
      expect(leadsTabStatus('all'), isNull);
      expect(leadsTabStatus('NEW'), 'NEW');
      expect(leadsTabStatus('LOST'), 'LOST');
    });
  });

  group('visits tabs', () {
    test('seven tabs in schedule order', () {
      expect(
        visitsTabs.map((VisitsTab t) => t.id).toList(),
        <String>[
          'all',
          'ASSIGNED',
          'ACCEPTED',
          'CHECK_IN',
          'IN_PROGRESS',
          'COMPLETED',
          'CANCELLED',
        ],
      );
    });

    test('all tab is unfiltered, states map to themselves', () {
      expect(visitsTabStatus('all'), isNull);
      expect(visitsTabStatus('ASSIGNED'), 'ASSIGNED');
      expect(visitsTabStatus('COMPLETED'), 'COMPLETED');
    });
  });

  group('lead detail crossroads', () {
    Map<String, dynamic> detailJson() {
      return <String, dynamic>{
        '_id': 'l1',
        'leadCode': 'LD-1',
        'status': 'VISIT_SCHEDULED',
        'visits': <dynamic>[
          <String, dynamic>{
            '_id': 'v1',
            'status': 'ASSIGNED',
            'executive': <String, dynamic>{'_id': 'e1', 'name': 'Ravi', 'mobile': '9000000002'},
          },
        ],
        'followUps': <dynamic>[
          <String, dynamic>{'_id': 'f1', 'status': 'PENDING', 'mode': 'CALL'},
        ],
        'hold': <String, dynamic>{'_id': 'h1', 'principal': 50000, 'total': 52500, 'status': 'ACTIVE'},
        'sale': null,
        'loanRequests': <dynamic>[
          <String, dynamic>{'_id': 'lr1', 'status': 'OFFERS_PENDING', 'requestedAmount': 5000000},
        ],
      };
    }

    test('joins visits, follow-ups, hold and loan status', () {
      final RealEstateLeadDetail detail = RealEstateLeadDetail.fromJson(detailJson());
      expect(detail.lead.id, 'l1');
      expect(detail.visits.length, 1);
      expect(detail.visits.first.executiveName, 'Ravi');
      expect(detail.followUps.length, 1);
      expect(detail.hold?.principal, 50000);
      expect(detail.sale, isNull);
      expect(detail.latestLoanStatus, 'OFFERS_PENDING');
    });

    test('empty crossroads degrade to empties, never crashes', () {
      final RealEstateLeadDetail detail = RealEstateLeadDetail.fromJson(<String, dynamic>{'_id': 'l2'});
      expect(detail.visits, isEmpty);
      expect(detail.followUps, isEmpty);
      expect(detail.hold, isNull);
      expect(detail.sale, isNull);
      expect(detail.latestLoanStatus, isNull);
    });
  });

  group('entitlement balance', () {
    RealEstateEntitlementModel entitlement({int? total, int consumed = 0}) {
      return RealEstateEntitlementModel.fromJson(<String, dynamic>{
        '_id': 'e-${total ?? 'null'}-$consumed',
        'totalCount': total,
        'consumedCount': consumed,
      });
    }

    test('limited entitlements report the remainder', () {
      expect(entitlementRemaining(entitlement(total: 10, consumed: 3)), 7);
      expect(entitlementRemaining(entitlement(total: 5, consumed: 5)), 0);
    });

    test('unlimited is the -1 sentinel, like the server math', () {
      expect(entitlementRemaining(entitlement(total: null)), -1);
    });

    test('any unlimited package makes the total unlimited', () {
      expect(
        totalRemaining(<RealEstateEntitlementModel>[
          entitlement(total: 10, consumed: 3),
          entitlement(total: null),
        ]),
        -1,
      );
      expect(
        totalRemaining(<RealEstateEntitlementModel>[
          entitlement(total: 10, consumed: 3),
          entitlement(total: 5, consumed: 1),
        ]),
        11,
      );
      expect(totalRemaining(<RealEstateEntitlementModel>[]), 0);
    });
  });

  group('vendor nav registries', () {    test('bottom tabs in shell order', () {
      expect(
        vendorTabs.map((VendorTab t) => t.id).toList(),
        <String>['dashboard', 'listings', 'leads', 'visits', 'more'],
      );
    });

    test('more menu grows as features land', () {
      expect(
        vendorMoreItems.map((VendorMoreItem m) => m.id).toList(),
        <String>[
          'customers',
          'packages',
          'payments',
          'documents',
          'analytics',
          'commissions',
          'support',
          'profile',
        ],
      );
    });
  });
}
