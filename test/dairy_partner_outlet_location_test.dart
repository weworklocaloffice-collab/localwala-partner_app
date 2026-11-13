import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/modules/dairy/partner/partner_outlet_location_view.dart';

class _OutletLocationRepository extends PartnerRepository {
  String? savedAddress;
  double? savedLongitude;
  double? savedLatitude;

  @override
  Future<DioApiResponse> partnerBusinessProfile() async => DioApiResponse.success(
        jsonEncode(<String, dynamic>{
          'profile': <String, dynamic>{
            'address': '',
            'city': <String, dynamic>{'name': 'Hyderabad'},
            'locality': <String, dynamic>{
              'name': 'Alwal',
              'location': <String, dynamic>{
                'type': 'Point',
                'coordinates': <double>[78.512, 17.515],
              },
            },
            'coordinates': null,
            'locationComplete': false,
          },
        }),
      );

  @override
  Future<DioApiResponse> updatePartnerOutletLocation({
    required String address,
    required double longitude,
    required double latitude,
  }) async {
    savedAddress = address;
    savedLongitude = longitude;
    savedLatitude = latitude;
    return DioApiResponse.success(jsonEncode(<String, dynamic>{
      'profile': <String, dynamic>{'locationComplete': true},
    }));
  }
}

void main() {
  testWidgets('partner must provide a complete address and map coordinates before save', (WidgetTester tester) async {
    final _OutletLocationRepository repository = _OutletLocationRepository();
    bool saved = false;
    await tester.pumpWidget(MaterialApp(
      home: Builder(builder: (BuildContext context) => Scaffold(
        body: Center(child: FilledButton(
          onPressed: () => Navigator.of(context).push<void>(MaterialPageRoute<void>(
            builder: (_) => PartnerOutletLocationScreen(
              repository: repository,
              onSaved: () => saved = true,
            ),
          )),
          child: const Text('Open setup'),
        )),
      )),
    ));
    await tester.tap(find.text('Open setup'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Primary locality: Alwal, Hyderabad'), findsOneWidget);
    expect(find.textContaining('not surveyed boundaries'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Complete outlet address'), '12 Dairy Road, Alwal, Hyderabad 500010');
    await tester.enterText(find.widgetWithText(TextField, 'Latitude'), '17.515');
    await tester.enterText(find.widgetWithText(TextField, 'Longitude'), '78.512');
    final Finder saveButton = find.text('Save and unlock operations');
    await tester.scrollUntilVisible(
      saveButton,
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(repository.savedAddress, '12 Dairy Road, Alwal, Hyderabad 500010');
    expect(repository.savedLongitude, 78.512);
    expect(repository.savedLatitude, 17.515);
    expect(saved, isTrue);
    expect(find.text('Open setup'), findsOneWidget);
  });
}
