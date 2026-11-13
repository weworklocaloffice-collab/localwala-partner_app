import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/modules/dairy/partner/partner_coverage_view.dart';

class _CoverageRepository extends PartnerRepository {
  int coverageLoads = 0;
  List<String>? submittedIds;
  String? submittedMessage;
  Map<String, dynamic>? latestRequest;
  bool includeZoneGroups = true;
  bool omitFlatNearbyLocalities = false;
  bool omitZoneLocalityStates = false;

  @override
  Future<DioApiResponse> coverage() async {
    coverageLoads++;
    final Map<String, dynamic> coverage = <String, dynamic>{
      'city': <String, dynamic>{'id': 'city-1', 'name': 'Hyderabad'},
      'eligibleZone': <String, dynamic>{
        'id': 'zone-north',
        'name': 'North Alwal',
        'version': 2,
      },
      'activeLocalities': <dynamic>[
        <String, dynamic>{'id': 'locality-active', 'name': 'Banjara Hills'},
      ],
      'nearbyLocalities': omitFlatNearbyLocalities
          ? <dynamic>[]
          : <dynamic>[
        <String, dynamic>{
          'id': 'locality-nearby',
          'name': 'Jubilee Hills',
        },
        <String, dynamic>{
          'id': 'locality-balanagar',
          'name': 'Balanagar',
        },
      ],
      if (includeZoneGroups) ...<String, dynamic>{
        'zoneGroups': <dynamic>[
          <String, dynamic>{
            'id': 'zone-north',
            'name': 'North Alwal',
            'version': 2,
            'localities': <dynamic>[
              <String, dynamic>{
                'id': 'locality-nearby',
                'name': 'Jubilee Hills',
                if (!omitZoneLocalityStates) 'state': 'requestable',
              },
              <String, dynamic>{
                'id': 'locality-balanagar',
                'name': 'Balanagar',
                if (!omitZoneLocalityStates) 'state': 'requestable',
              },
            ],
          },
        ],
        'ungroupedNearbyLocalities': <dynamic>[],
      },
      if (submittedIds != null)
        'pendingRequest': <String, dynamic>{
          'status': 'pending',
          'requestedLocalities': <dynamic>[
            <String, dynamic>{'id': 'locality-nearby', 'name': 'Jubilee Hills'},
          ],
        },
      if (latestRequest != null) 'latestRequest': latestRequest,
    };
    return DioApiResponse.success(
      jsonEncode(<String, dynamic>{'coverage': coverage}),
    );
  }

  @override
  Future<DioApiResponse> requestCoverage({
    required List<String> localityIds,
    String message = '',
  }) async {
    submittedIds = localityIds;
    submittedMessage = message;
    return const DioApiResponse.success('{"request":{"status":"pending"}}');
  }
}

void main() {
  testWidgets(
    'partner sees active area and requests localities in its published zone',
    (WidgetTester tester) async {
      final _CoverageRepository repository = _CoverageRepository()
        ..omitFlatNearbyLocalities = true
        ..omitZoneLocalityStates = true;
      await tester.pumpWidget(
        MaterialApp(home: PartnerCoverageScreen(repository: repository)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hyderabad'), findsOneWidget);
      expect(find.text('Banjara Hills'), findsOneWidget);
      expect(find.text('Jubilee Hills'), findsOneWidget);
      expect(find.textContaining('published delivery zone'), findsOneWidget);

      await tester.tap(find.text('Jubilee Hills'));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Request selected localities (1)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Request selected localities (1)'), findsOneWidget);
      await tester.enterText(
        find.byType(TextField),
        'Serving this neighborhood daily',
      );
      await tester.tap(find.text('Request selected localities (1)'));
      await tester.pumpAndSettle();

      expect(repository.submittedIds, <String>['locality-nearby']);
    expect(repository.submittedMessage, 'Serving this neighborhood daily');
      expect(repository.coverageLoads, 2);
      expect(
        find.textContaining('waiting for platform review'),
        findsOneWidget,
      );
    },
  );

  testWidgets('partner sees locality-by-locality approval outcomes', (
    WidgetTester tester,
  ) async {
    final _CoverageRepository repository = _CoverageRepository()
      ..latestRequest = <String, dynamic>{
        'status': 'partially_approved',
        'localityReviews': <dynamic>[
          <String, dynamic>{
            'locality': <String, dynamic>{'id': 'locality-kompally', 'name': 'Kompally'},
            'status': 'approved',
          },
          <String, dynamic>{
            'locality': <String, dynamic>{'id': 'locality-dulapally', 'name': 'Dulapally'},
            'status': 'rejected',
            'reviewNote': 'Outside current capacity',
          },
        ],
      };

    await tester.pumpWidget(
      MaterialApp(home: PartnerCoverageScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Kompally: approved'), findsOneWidget);
    expect(
      find.textContaining('Dulapally: declined (Outside current capacity)'),
      findsOneWidget,
    );
  });

  testWidgets('partner can request an additional locality from its zone', (
    WidgetTester tester,
  ) async {
    final _CoverageRepository repository = _CoverageRepository()
      ..includeZoneGroups = true;
    await tester.pumpWidget(
      MaterialApp(home: PartnerCoverageScreen(repository: repository)),
    );
    await tester.pumpAndSettle();

    expect(find.text('North Alwal'), findsOneWidget);
    expect(find.text('Balanagar'), findsOneWidget);
    await tester.ensureVisible(find.text('Balanagar'));
    await tester.tap(find.text('Balanagar'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Request selected localities (1)'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Request selected localities (1)'), findsOneWidget);
    await tester.tap(find.text('Request selected localities (1)'));
    await tester.pumpAndSettle();
    expect(repository.submittedIds, <String>['locality-balanagar']);
  });
}
