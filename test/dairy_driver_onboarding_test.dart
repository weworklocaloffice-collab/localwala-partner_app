import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/core/repositories/delivery_repository.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/modules/dairy/driver/delivery_shell_view.dart';
import 'package:partner/app/modules/dairy/partner/driver_list/partner_driver_list_view.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class _PartnerRepository extends PartnerRepository {
  @override
  Future<DioApiResponse> drivers({
    int page = 1,
    int limit = ApiRequestService.pageSize,
  }) async => const DioApiResponse.success(
    '{"drivers":[{"id":"driver-1","approvalStatus":"pending","activeStatus":false,"isBlocked":false,"status":true,"payoutMode":"per_can","payoutRate":5,"userId":{"firstName":"Sam","lastName":"Rider","mobile":9876543210,"isMobileVerified":true}}]}',
  );

  @override
  Future<DioApiResponse> driverInvites() async =>
      const DioApiResponse.success('{"invites":[]}');
}

class _UnverifiedPartnerRepository extends PartnerRepository {
  @override
  Future<DioApiResponse> drivers({
    int page = 1,
    int limit = ApiRequestService.pageSize,
  }) async => const DioApiResponse.success(
    '{"drivers":[{"id":"driver-new","approvalStatus":"pending","activeStatus":false,"isBlocked":false,"status":true,"payoutMode":"per_can","userId":{"firstName":"New","lastName":"Rider","mobile":9876543210,"isMobileVerified":false}}]}',
  );

  @override
  Future<DioApiResponse> driverInvites() async =>
      const DioApiResponse.success('{"invites":[]}');
}

class _PendingDeliveryRepository extends DeliveryRepository {
  @override
  Future<DioApiResponse> onboardingStatus() async =>
      const DioApiResponse.success(
        '{"onboarding":{"status":"pending","outletName":"North Dairy","canDeliver":false}}',
      );
}

void main() {
  testWidgets('partner roster clearly marks a new rider pending approval', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PartnerDriverListScreen(repository: _PartnerRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sam Rider · 9876543210'), findsOneWidget);
    expect(find.text('Pending approval'), findsOneWidget);
    expect(find.text('Reject application'), findsNothing);
  });

  testWidgets('an owner-created account waits for phone verification', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PartnerDriverListScreen(repository: _UnverifiedPartnerRepository()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Awaiting phone verification'), findsOneWidget);
    expect(find.text('Reject application'), findsNothing);
    expect(find.text('Create driver account'), findsOneWidget);
  });

  testWidgets('owner can enter driver account details in Partner app', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PartnerDriverListScreen(repository: _PartnerRepository()),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create driver account'));
    await tester.pumpAndSettle();

    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Last name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Vehicle type'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('unapproved rider sees the outlet approval waiting screen', (
    WidgetTester tester,
  ) async {
    const UserSessionModel session = UserSessionModel(
      id: 'driver-1',
      role: 'dairyDriver',
      activeRole: DairyAppRole.driver,
      availableRoles: <DairyAppRole>[DairyAppRole.driver],
    );
    const RoleGateState gate = RoleGateState(
      status: RoleGateStatus.resolved,
      session: session,
      activeRole: DairyAppRole.driver,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DeliveryShellScreen(
          gate: gate,
          repository: _PendingDeliveryRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Waiting for outlet approval'), findsOneWidget);
    expect(find.textContaining('North Dairy'), findsOneWidget);
    expect(find.text('Check again'), findsOneWidget);
  });
}
