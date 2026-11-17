/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright Â© 2026 WeWorkLocal.
 * All Rights Reserved.
 *
 * Website: https://localwala.tech
 * Email: weworklocal1@gmail.com
 *
 * Proprietary and Confidential.
 */

import 'package:partner/app/core/config/shared_pref_keys.dart';
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:partner/app/core/services/offline_can_scan_queue.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:partner/app/shell/role_gate/role_gate_view.dart';
import 'package:partner/app/presentation/styles/app_localization/app_localization_bloc.dart';
import 'package:partner/app/presentation/styles/theme.dart';
import 'package:partner/app/presentation/styles/theme_bloc/theme_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';
import 'package:partner/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrap(Widget child) {
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<ThemeBloc>(create: (_) => ThemeBloc()),
        BlocProvider<AppLocalizationBloc>(create: (_) => AppLocalizationBloc()),
        BlocProvider<RoleGateBloc>(create: (_) => RoleGateBloc()..add(const RoleGateResolveEvent())),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: getThemeData(AppTheme.light),
        home: child,
      ),
    );
  }

  group('DairyAppRole', () {
    test('maps wire values both ways', () {
      expect(DairyAppRole.fromWire('dairyPartner'), DairyAppRole.partner);
      expect(DairyAppRole.fromWire('dairyDriver'), DairyAppRole.driver);
      expect(DairyAppRole.fromWire('nonsense'), isNull);
      expect(DairyAppRole.partner.wire, 'dairyPartner');
      expect(DairyAppRole.driver.wire, 'dairyDriver');
    });
  });

  group('UserSessionModel.fromJson', () {
    test('treats an owner-operator as dual role', () {
      final UserSessionModel session = UserSessionModel.fromJson(<String, dynamic>{
        'id': 'u1',
        'availableRoles': <String>['dairyPartner', 'dairyDriver'],
        'activeRole': 'dairyPartner',
      });

      expect(session.availableRoles.length, 2);
      expect(session.canSwitchRole, isTrue);
      expect(session.isPartner, isTrue);
      expect(otherRoleOf(session), DairyAppRole.driver);
    });

    test('a pure rider is single role and cannot switch', () {
      final UserSessionModel session = UserSessionModel.fromJson(<String, dynamic>{
        'id': 'u2',
        'availableRoles': <String>['dairyDriver'],
      });

      expect(session.canSwitchRole, isFalse);
      expect(session.activeRole, DairyAppRole.driver);
      expect(session.isDriver, isTrue);
    });

    test('ignores an active role the session does not hold', () {
      final UserSessionModel session = UserSessionModel.fromJson(<String, dynamic>{
        'id': 'u3',
        'availableRoles': <String>['dairyPartner'],
        'activeRole': 'dairyDriver',
      });

      expect(session.activeRole, DairyAppRole.partner);
    });

    test('falls back to partner when no roles are present', () {
      final UserSessionModel session = UserSessionModel.fromJson(<String, dynamic>{'id': 'u4'});
      expect(session.activeRole, DairyAppRole.partner);
      expect(session.canSwitchRole, isFalse);
    });

    test('survives a session round trip', () {
      const UserSessionModel original = UserSessionModel(
        id: 'u5',
        firstName: 'Asha',
        availableRoles: <DairyAppRole>[DairyAppRole.partner, DairyAppRole.driver],
        activeRole: DairyAppRole.driver,
        ownDeliveryPartner: true,
        driverPayoutMode: 'business_pays',
      );

      final UserSessionModel parsed = UserSessionModel.fromJson(original.toJson());

      expect(parsed.id, 'u5');
      expect(parsed.firstName, 'Asha');
      expect(parsed.availableRoles.length, 2);
      expect(parsed.activeRole, DairyAppRole.driver);
      expect(parsed.ownDeliveryPartner, isTrue);
      expect(parsed.agentMode, DairyAgentMode.ownFleet);
    });
  });

  group('vertical choice', () {
    test('a pre-vertical server defaults to dairy-only and never prompts', () {
      final UserSessionModel session = UserSessionModel.fromJson(<String, dynamic>{
        'id': 'v1',
        'availableRoles': <String>['dairyPartner'],
      });

      expect(session.availableVerticals, <String>['dairy']);
      expect(session.activeVertical, '');
      expect(session.needsVerticalChoice, isFalse);
    });

    test('more than one vertical with no persisted pick prompts the picker', () {
      final UserSessionModel session = UserSessionModel.fromJson(<String, dynamic>{
        'id': 'v2',
        'availableRoles': <String>['dairyPartner'],
        'availableVerticals': <String>['dairy', 'realestate'],
      });

      expect(session.needsVerticalChoice, isTrue);
    });

    test('a persisted pick silences the picker and survives a round trip', () {
      final UserSessionModel session = UserSessionModel.fromJson(<String, dynamic>{
        'id': 'v3',
        'availableRoles': <String>['dairyPartner'],
        'availableVerticals': <String>['dairy', 'realestate'],
        'activeVertical': 'realestate',
      });

      expect(session.needsVerticalChoice, isFalse);

      final UserSessionModel parsed = UserSessionModel.fromJson(session.toJson());
      expect(parsed.activeVertical, 'realestate');
      expect(parsed.availableVerticals, <String>['dairy', 'realestate']);
    });

    test('ignores an active vertical the session does not hold', () {
      final UserSessionModel session = UserSessionModel.fromJson(<String, dynamic>{
        'id': 'v4',
        'availableRoles': <String>['dairyPartner'],
        'availableVerticals': <String>['dairy'],
        'activeVertical': 'realestate',
      });

      expect(session.activeVertical, '');
      expect(session.needsVerticalChoice, isFalse);
    });
  });

  group('real estate shells', () {
    test('a dairy-only session holds no shells', () {
      final UserSessionModel session = UserSessionModel.fromJson(<String, dynamic>{
        'id': 'r1',
        'availableRoles': <String>['dairyPartner'],
      });

      expect(session.availableRealEstateShells, isEmpty);
      expect(session.activeRealEstateShell, '');
    });

    test('the first available shell becomes active', () {
      final UserSessionModel session = UserSessionModel.fromJson(<String, dynamic>{
        'id': 'r2',
        'availableRoles': <String>['dairyPartner'],
        'availableVerticals': <String>['dairy', 'realestate'],
        'availableRealEstateShells': <String>['vendor', 'executive'],
      });

      expect(session.activeRealEstateShell, 'vendor');
    });

    test('a persisted shell pick survives and round-trips', () {
      final UserSessionModel session = UserSessionModel.fromJson(<String, dynamic>{
        'id': 'r3',
        'availableRoles': <String>['dairyPartner'],
        'availableVerticals': <String>['dairy', 'realestate'],
        'availableRealEstateShells': <String>['vendor', 'executive'],
        'activeVertical': 'realestate',
        'activeRealEstateShell': 'executive',
      });

      expect(session.activeRealEstateShell, 'executive');

      final UserSessionModel parsed = UserSessionModel.fromJson(session.toJson());
      expect(parsed.availableRealEstateShells, <String>['vendor', 'executive']);
      expect(parsed.activeRealEstateShell, 'executive');
    });

    test('an unknown persisted shell degrades to the first available', () {
      final UserSessionModel session = UserSessionModel.fromJson(<String, dynamic>{
        'id': 'r4',
        'availableRoles': <String>['dairyPartner'],
        'availableVerticals': <String>['dairy', 'realestate'],
        'availableRealEstateShells': <String>['executive'],
        'activeRealEstateShell': 'vendor',
      });

      expect(session.activeRealEstateShell, 'executive');
    });
  });

  group('DairyAgentMode', () {
    test('own fleet only when the business owns its delivery', () {
      const UserSessionModel ownFleet = UserSessionModel(id: 'a', ownDeliveryPartner: true);
      const UserSessionModel platform = UserSessionModel(id: 'b');

      expect(ownFleet.agentMode, DairyAgentMode.ownFleet);
      expect(platform.agentMode, DairyAgentMode.platformPool);
      expect(DairyAgentMode.fromWire('own_fleet'), DairyAgentMode.ownFleet);
      expect(DairyAgentMode.fromWire(null), DairyAgentMode.platformPool);
    });
  });

  group('SharedPreferencesKey', () {
    test('session scope covers every auth-scoped key', () {
      const AuthKeys keys = AuthKeys();
      expect(keys.sessionScoped, contains(keys.authToken));
      expect(keys.sessionScoped, contains(keys.authRefreshToken));
      expect(keys.sessionScoped, contains(keys.uid));
      expect(keys.sessionScoped, contains(keys.session));
      expect(keys.sessionScoped, contains(keys.activeRole));
      // Nothing token-shaped may be left behind after logout.
      expect(keys.sessionScoped.every((String k) => k.startsWith('_dairy')), isTrue);
    });
  });

  group('AuthRepository persistence', () {
    late AuthRepository repository;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      repository = AuthRepository(prefs: await SharedPreferences.getInstance());
    });

    test('starts logged out', () async {
      expect(await repository.isLoggedIn(), isFalse);
      expect(await repository.session(), isNull);
    });

    test('isLoggedIn only after tokens are saved', () async {
      await repository.saveTokens(accessToken: 'access-1', refresh: 'refresh-1');

      expect(await repository.authToken(), 'access-1');
      expect(await repository.refreshToken(), 'refresh-1');
      expect(await repository.isLoggedIn(), isTrue);
    });

    test('saveSession persists the serialised session and uid', () async {
      const UserSessionModel session = UserSessionModel(
        id: 'u9',
        firstName: 'Ravi',
        availableRoles: <DairyAppRole>[DairyAppRole.driver],
        activeRole: DairyAppRole.driver,
      );

      await repository.saveSession(session);

      expect(await repository.uid(), 'u9');
      final UserSessionModel? loaded = await repository.session();
      expect(loaded, isNotNull);
      expect(loaded!.id, 'u9');
      expect(loaded.activeRole, DairyAppRole.driver);
    });

    test('saveActiveRole rewrites the stored session', () async {
      const UserSessionModel session = UserSessionModel(
        id: 'u10',
        availableRoles: <DairyAppRole>[DairyAppRole.partner, DairyAppRole.driver],
        activeRole: DairyAppRole.partner,
      );
      await repository.saveSession(session);

      await repository.saveActiveRole(DairyAppRole.driver);

      final UserSessionModel? loaded = await repository.session();
      expect(loaded!.activeRole, DairyAppRole.driver);
      expect(loaded.availableRoles.length, 2, reason: 'switching must not drop the other role');
    });

    test('logout clears every session-scoped key', () async {
      const UserSessionModel session = UserSessionModel(
        id: 'u11',
        availableRoles: <DairyAppRole>[DairyAppRole.driver],
      );
      await repository.saveTokens(accessToken: 'access-2', refresh: 'refresh-2');
      await repository.saveSession(session);
      await repository.saveActiveRole(DairyAppRole.driver);

      await repository.logout();

      expect(await repository.isLoggedIn(), isFalse);
      expect(await repository.session(), isNull);
      expect(await repository.uid(), isNull);
      expect(await repository.refreshToken(), isNull);
    });
  });

  group('OfflineCanScanQueue', () {
    late OfflineCanScanQueue queue;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      queue = OfflineCanScanQueue();
    });

    PendingCanScan scan(String clientRef, DairyCanScanType type, List<String> codes) {
      return PendingCanScan(
        clientRef: clientRef,
        runId: 'run-1',
        type: type,
        canCodes: codes,
        capturedAt: DateTime(2026, 10, 4),
      );
    }

    test('enqueue then acknowledge drains the outbox', () async {
      await queue.enqueue(scan('a', DairyCanScanType.issue, <String>['C1']));
      await queue.enqueue(scan('b', DairyCanScanType.collect, <String>['C2']));
      expect(await queue.count(), 2);

      await queue.acknowledge(<String>['a']);

      final List<PendingCanScan> remaining = await queue.pending();
      expect(remaining.length, 1);
      expect(remaining.first.clientRef, 'b');
    });

    test('clientRef dedupes so a retry cannot double count a can', () async {
      await queue.enqueue(scan('same', DairyCanScanType.issue, <String>['C1']));
      await queue.enqueue(scan('same', DairyCanScanType.issue, <String>['C1']));

      expect(await queue.count(), 1);
    });

    test('balanceForRun nets issues against collections', () async {
      await queue.enqueue(scan('a', DairyCanScanType.issue, <String>['C1', 'C2']));
      await queue.enqueue(scan('b', DairyCanScanType.collect, <String>['C2']));

      final Map<DairyCanScanType, int> balance = await queue.balanceForRun('run-1');

      expect(balance[DairyCanScanType.issue], 2);
      expect(balance[DairyCanScanType.collect], -1);
    });

    test('newClientRef is unique across rapid calls', () {
      expect(OfflineCanScanQueue.newClientRef(), isNot(OfflineCanScanQueue.newClientRef()));
    });
  });

  testWidgets('role gate renders both shells of the merged app', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const RoleGateScreen()));
    await tester.pump();

    expect(find.text('Partner'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
  });

  testWidgets('app boots to splash', (WidgetTester tester) async {
    await tester.pumpWidget(const DairyPartnerApp());
    await tester.pump();

    expect(find.byType(Scaffold), findsWidgets);
  });
}

/// The role that is not currently active, or null.
DairyAppRole? otherRoleOf(UserSessionModel session) {
  for (final DairyAppRole role in session.availableRoles) {
    if (role != session.activeRole) return role;
  }
  return null;
}