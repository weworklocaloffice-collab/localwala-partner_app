import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/core/repositories/partner_repository.dart';
import 'package:partner/app/modules/dairy/partner/dashboard/partner_dashboard_view.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class _DashboardRepository extends PartnerRepository {
  String? requestedPeriod;

  @override
  Future<DioApiResponse> dashboard({String period = '7d'}) async {
    requestedPeriod = period;
    return DioApiResponse.success(jsonEncode(<String, dynamic>{
      'dashboard': <String, dynamic>{
        'generatedAt': '2026-11-06T09:30:00.000Z',
        'outlet': <String, dynamic>{
          'name': 'Green Valley Dairy',
          'locality': <String, dynamic>{'name': 'Alwal'},
          'city': <String, dynamic>{'name': 'Hyderabad'},
        },
        'today': <String, dynamic>{
          'ok': true,
          'data': <String, dynamic>{
            'orders': 7,
            'revenue': 840,
            'byStatus': <String, dynamic>{
              'confirmed': <String, dynamic>{'orders': 2},
              'preparing': <String, dynamic>{'orders': 1},
            },
          },
        },
        'salesTrend': <String, dynamic>{
          'ok': true,
          'data': <String, dynamic>{
            'periodDays': 7,
            'totalOrders': 18,
            'totalRevenue': 2540,
            'previousOrders': 15,
            'previousRevenue': 2300,
            'days': <dynamic>[
              <String, dynamic>{'date': '2026-10-31', 'orders': 1, 'revenue': 100},
              <String, dynamic>{'date': '2026-11-01', 'orders': 2, 'revenue': 250},
              <String, dynamic>{'date': '2026-11-02', 'orders': 1, 'revenue': 150},
              <String, dynamic>{'date': '2026-11-03', 'orders': 3, 'revenue': 400},
              <String, dynamic>{'date': '2026-11-04', 'orders': 2, 'revenue': 300},
              <String, dynamic>{'date': '2026-11-05', 'orders': 2, 'revenue': 500},
              <String, dynamic>{'date': '2026-11-06', 'orders': 7, 'revenue': 840},
            ],
          },
        },
        'lowStock': <String, dynamic>{
          'ok': true,
          'data': <String, dynamic>{
            'count': 1,
            'threshold': 5,
            'items': <dynamic>[],
          },
        },
        'compliance': <String, dynamic>{
          'ok': true,
          'data': <String, dynamic>{'status': 'valid'},
        },
        'payables': <String, dynamic>{
          'ok': false,
          'error': 'SECRET_DB_ERROR details must not reach partners',
        },
        'subscriptions': <String, dynamic>{
          'ok': true,
          'data': <String, dynamic>{'active': 4},
        },
        'deliveries': <String, dynamic>{
          'ok': true,
          'data': <String, dynamic>{
            'runsInProgress': 1,
            'stopsPending': 6,
          },
        },
      },
    }));
  }
}

void main() {
  testWidgets('partner dashboard shows outlet metrics and quick navigation', (
    WidgetTester tester,
  ) async {
    int? destination;
    final _DashboardRepository repository = _DashboardRepository();
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PartnerDashboardScreen(
          gate: const RoleGateState(
            status: RoleGateStatus.resolved,
            session: UserSessionModel(
              id: 'partner-1',
              firstName: 'Asha',
              lastName: 'Kumar',
            ),
          ),
          partnerRepository: repository,
          onNavigate: (int index) => destination = index,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Green Valley Dairy'), findsWidgets);
    expect(find.text('Alwal, Hyderabad'), findsOneWidget);
    expect(find.text('Ready to operate'), findsOneWidget);
    expect(repository.requestedPeriod, '7d');
    expect(find.text('Business overview'), findsOneWidget);
    expect(find.text('Needs attention'), findsOneWidget);
    expect(find.text('Orders to process: 3'), findsOneWidget);
    expect(find.textContaining('Updated at '), findsOneWidget);
    expect(find.textContaining('SECRET_DB_ERROR'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Today at a glance'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Today at a glance'), findsOneWidget);
    expect(find.text('Some panels could not load'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('840'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('₹840'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('30 days'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('30 days'));
    await tester.pumpAndSettle();
    expect(repository.requestedPeriod, '30d');
    await tester.drag(find.byType(ListView).first, const Offset(0, 1200));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, 'Inventory'));
    expect(destination, 2);
  });

  testWidgets('dashboard waits for admin verification before asking for outlet location', (
    WidgetTester tester,
  ) async {
    bool refreshed = false;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PartnerDashboardScreen(
          gate: const RoleGateState(status: RoleGateStatus.resolved),
          outletVerified: false,
          outletLocationComplete: false,
          partnerRepository: _DashboardRepository(),
          onRefreshOutletStatus: () => refreshed = true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Waiting for admin verification'), findsOneWidget);
    expect(find.text('Complete your outlet location'), findsNothing);
    await tester.tap(find.text('Waiting for admin verification'));
    expect(refreshed, isTrue);
  });
}
