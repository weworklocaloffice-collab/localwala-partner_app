import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/modules/dairy/partner/partner_more_view.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

void main() {
  testWidgets('operational pages are gated while outlet location is incomplete', (WidgetTester tester) async {
    bool requestedSetup = false;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PartnerMoreScreen(
        session: const UserSessionModel(id: 'partner-1'),
        locationComplete: false,
        onLocationRequired: () => requestedSetup = true,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Business availability'));
    expect(requestedSetup, isTrue);
    expect(find.text('Set opening hours, order cut-off and active localities'), findsOneWidget);
  });

  testWidgets('outlet location is not requested before admin verification', (WidgetTester tester) async {
    bool requestedSetup = false;
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: PartnerMoreScreen(
        session: const UserSessionModel(id: 'partner-1'),
        outletVerified: false,
        locationComplete: false,
        onLocationRequired: () => requestedSetup = true,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Waiting for admin verification'), findsOneWidget);
    expect(find.text('Outlet address and pin'), findsNothing);
    await tester.tap(find.text('Business availability'));
    expect(requestedSetup, isTrue);
  });

  testWidgets('partner More groups secondary workflows and account access', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const PartnerMoreScreen(
          session: UserSessionModel(
            id: 'partner-1',
            firstName: 'Asha',
            lastName: 'Kumar',
            email: 'asha@example.com',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Operations'), findsOneWidget);
    expect(find.text('Asha Kumar'), findsOneWidget);
    final Finder scrollable = find.byType(Scrollable).first;
    for (final String title in <String>[
      'Delivery area',
      'Business availability',
      'Marketing & promotions',
      'Runs',
      'Drivers',
      'Finance',
      'Earnings',
    ]) {
      await tester.scrollUntilVisible(find.text(title), 180, scrollable: scrollable);
      await tester.ensureVisible(find.text(title));
      expect(find.text(title), findsOneWidget);
    }
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsNWidgets(2));
  });
}
