import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/presentation/pages/account/profile_view.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class _ProfileRepository extends PartnerRepository {
  _ProfileRepository(this.profile);

  final Map<String, dynamic> profile;
  bool requestedPartnerProfile = false;

  @override
  Future<DioApiResponse> partnerBusinessProfile() async {
    requestedPartnerProfile = true;
    return DioApiResponse.success(jsonEncode(<String, dynamic>{'profile': profile}));
  }
}

void main() {
  testWidgets('Dairy Partner profile shows real outlet and account details', (
    WidgetTester tester,
  ) async {
    final _ProfileRepository repository = _ProfileRepository(
      <String, dynamic>{
        'name': 'Meadow Dairy Cooperative',
        'code': 'MDC-204',
        'businessModel': 'commission_partner',
        'verified': true,
        'city': <String, dynamic>{'name': 'Pune'},
        'locality': <String, dynamic>{'name': 'Kothrud'},
      },
    );
    const UserSessionModel session = UserSessionModel(
      id: 'operator-1',
      firstName: 'Riya',
      lastName: 'Sharma',
      email: 'riya@example.com',
      mobile: '9876543210',
      countryCode: '91',
      business: 'outlet-204',
      availableRoles: <DairyAppRole>[
        DairyAppRole.partner,
        DairyAppRole.driver,
      ],
      activeRole: DairyAppRole.partner,
      ownDeliveryPartner: true,
      driverPayoutMode: 'business_pays',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(
          session: session,
          partnerRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedPartnerProfile, isTrue);
    expect(find.text('Business profile'), findsOneWidget);
    expect(find.text('Meadow Dairy Cooperative'), findsOneWidget);
    expect(find.text('Commission Partner'), findsOneWidget);
    expect(find.text('Verified'), findsOneWidget);
    expect(find.text('Outlet reference'), findsOneWidget);
    expect(find.text('Riya Sharma'), findsOneWidget);
    expect(find.text('+91 9876543210'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('In-house delivery fleet'),
      300,
    );
    expect(find.text('In-house delivery fleet'), findsOneWidget);
    expect(find.text('Business Pays'), findsOneWidget);
  });

  testWidgets('delivery role keeps its existing account profile', (
    WidgetTester tester,
  ) async {
    const UserSessionModel session = UserSessionModel(
      id: 'rider-1',
      firstName: 'Arun',
      activeRole: DairyAppRole.driver,
      availableRoles: <DairyAppRole>[DairyAppRole.driver],
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(session: session),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Agent source'), findsOneWidget);
  });

  testWidgets('franchise profile keeps the upfront fee visible until paid', (
    WidgetTester tester,
  ) async {
    final _ProfileRepository repository = _ProfileRepository(
      <String, dynamic>{
        'name': 'Meadow Dairy Cooperative',
        'businessModel': 'franchise',
        'verified': true,
        'requestedBusinessModel': 'franchise',
        'applicationStatus': 'approved',
        'agreementStatus': 'pending',
        'joiningFee': 15000,
        'joiningFeePaymentStatus': 'pending',
      },
    );
    const UserSessionModel session = UserSessionModel(
      id: 'operator-2',
      firstName: 'Riya',
      activeRole: DairyAppRole.partner,
      business: 'outlet-205',
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ProfileScreen(session: session, partnerRepository: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Requested partnership model'), findsOneWidget);
    expect(find.text('Franchise'), findsNWidgets(2));
    await tester.scrollUntilVisible(find.text('Pay joining fee'), 250);
    expect(find.text('₹15000.00 · Due'), findsOneWidget);
    expect(find.text('Pay joining fee'), findsOneWidget);
  });
}
