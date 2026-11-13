/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/modules/realestate/executive/executive_shell_view.dart';
import 'package:partner/app/modules/realestate/executive/visits/bloc/executive_visits_bloc.dart';
import 'package:partner/app/modules/realestate/models/follow_up.dart';

/// Executive shell contract: five tabs in order, visit tabs doubling as
/// status filters, and the follow-up wire shape the tab renders.
void main() {
  group('executive tabs', () {
    test('five tabs in shell order', () {
      expect(
        executiveTabs.map((ExecutiveTab t) => t.id).toList(),
        <String>['today', 'leads', 'visits', 'earnings', 'profile'],
      );
    });

    test('visit tabs in schedule order', () {
      expect(
        executiveVisitsTabs.map((ExecutiveVisitsTab t) => t.id).toList(),
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

    test('all tab is unfiltered', () {
      expect(executiveVisitsTabStatus('all'), isNull);
    });

    test('state tabs map to their own status', () {
      expect(executiveVisitsTabStatus('ASSIGNED'), 'ASSIGNED');
      expect(executiveVisitsTabStatus('COMPLETED'), 'COMPLETED');
    });
  });

  group('follow-up model', () {
    test('parses list rows', () {
      final RealEstateFollowUpModel f = RealEstateFollowUpModel.fromJson(<String, dynamic>{
        '_id': 'f1',
        'lead': 'l1',
        'executive': 'e1',
        'status': 'PENDING',
        'nextFollowUpAt': '2026-10-20T10:00:00.000Z',
        'mode': 'CALL',
        'notes': 'Call back',
      });
      expect(f.id, 'f1');
      expect(f.status, 'PENDING');
      expect(f.mode, 'CALL');
      expect(f.nextFollowUpAt, isNotNull);
    });
  });
}
