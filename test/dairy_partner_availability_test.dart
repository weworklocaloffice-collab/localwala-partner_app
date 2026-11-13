import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/modules/dairy/partner/partner_availability_view.dart';

class _AvailabilityRepository extends PartnerRepository {
  Map<String, dynamic>? saved;

  Map<String, dynamic> get payload => <String, dynamic>{
        'settings': <String, dynamic>{
          'acceptingOrders': true,
          'timezone': 'Asia/Kolkata',
          'orderCutoffTime': '20:30',
          'serviceabilityConfigured': true,
          'serviceableLocalities': <String>['loc-1'],
          'primaryLocalityId': 'loc-1',
          'orderAvailability': <String, dynamic>{
            'canAcceptOrders': true,
            'reason': 'open',
            'localTime': '10:30',
          },
          'operatingHours': List<Map<String, dynamic>>.generate(7, (int day) => <String, dynamic>{
            'day': day,
            'isOpen': day != 0,
            if (day != 0) 'opensAt': '06:00',
            if (day != 0) 'closesAt': '21:00',
          }),
          'specialHours': <Map<String, dynamic>>[
            <String, dynamic>{'date': '2026-12-25', 'isClosed': true, 'label': 'Holiday'},
          ],
        },
        'approvedLocalities': <Map<String, dynamic>>[
          <String, dynamic>{'_id': 'loc-1', 'name': 'Alwal'},
          <String, dynamic>{'_id': 'loc-2', 'name': 'Balanagar'},
        ],
      };

  @override
  Future<DioApiResponse> availability() async => DioApiResponse.success(jsonEncode(payload));

  @override
  Future<DioApiResponse> updateAvailability(Map<String, dynamic> settings) async {
    saved = settings;
    return DioApiResponse.success('{}');
  }
}

void main() {
  testWidgets('primary locality stays enabled while partner chooses additional approved localities', (WidgetTester tester) async {
    final _AvailabilityRepository repository = _AvailabilityRepository();
    await tester.pumpWidget(MaterialApp(home: PartnerAvailabilityScreen(repository: repository)));
    await tester.pumpAndSettle();

    expect(find.text('Business availability'), findsOneWidget);
    expect(find.text('Open for orders now'), findsOneWidget);
    final Finder scrollable = find.byType(Scrollable).first;
    final SwitchListTile acceptingOrders = tester.widget<SwitchListTile>(
      find.ancestor(of: find.text('Accepting new orders'), matching: find.byType(SwitchListTile)).first,
    );
    acceptingOrders.onChanged!(false);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.textContaining('Alwal'), 250, scrollable: scrollable);
    await tester.ensureVisible(find.textContaining('Alwal'));
    expect(find.textContaining('Alwal'), findsOneWidget);
    final CheckboxListTile alwal = tester.widget<CheckboxListTile>(find.ancestor(of: find.textContaining('Alwal'), matching: find.byType(CheckboxListTile)).first);
    expect(alwal.value, isTrue);
    expect(alwal.onChanged, isNull);
    await tester.scrollUntilVisible(find.text('Balanagar'), 200, scrollable: scrollable);
    await tester.ensureVisible(find.text('Balanagar'));
    final CheckboxListTile balanagar = tester.widget<CheckboxListTile>(
      find.ancestor(of: find.text('Balanagar'), matching: find.byType(CheckboxListTile)).first,
    );
    balanagar.onChanged!(true);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.textContaining('Holiday'), 250, scrollable: scrollable);
    expect(find.textContaining('Holiday'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Save availability'), 250, scrollable: scrollable);
    await tester.ensureVisible(find.text('Save availability'));
    tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!();
    await tester.pumpAndSettle();

    expect(repository.saved?['acceptingOrders'], isFalse);
    expect(repository.saved?['serviceableLocalities'], <String>['loc-1', 'loc-2']);
    expect((repository.saved?['operatingHours'] as List).length, 7);
    expect(repository.saved?['orderCutoffTime'], '20:30');
  });
}
