import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:partner/app/core/config/api_request_service.dart';
import 'package:partner/app/core/config/api_endpoints.dart';
import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:partner/app/presentation/pages/auth/register/bloc/registration_bloc.dart';
import 'package:partner/app/presentation/pages/auth/register/register_view.dart';
import 'package:partner/gen/l10n/app_localizations.dart';

class _AuthRepository extends AuthRepository {
  String? access;
  String? refresh;
  UserSessionModel? savedSession;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refresh,
  }) async {
    access = accessToken;
    this.refresh = refresh;
  }

  @override
  Future<void> saveSession(UserSessionModel session) async {
    // Include the cache round trip so the selected vertical survives reload.
    savedSession = UserSessionModel.fromJson(session.toJson());
  }
}

Future<void> _dispatch(
  RegistrationBloc bloc,
  RegistrationEvent event,
  bool Function(RegistrationState) ready,
) async {
  final Future<RegistrationState> next = bloc.stream.firstWhere(ready);
  bloc.add(event);
  await next.timeout(const Duration(seconds: 5));
}

void main() {
  testWidgets('registration offers partner verticals and dairy driver', (
    WidgetTester tester,
  ) async {
    final List<String> requests = <String>[];
    final RegistrationBloc bloc = RegistrationBloc(
      request:
          (
            String endpoint, {
            String method = 'POST',
            Map<String, dynamic>? body,
          }) async {
            requests.add(endpoint);
            return const DioApiResponse.success('{}');
          },
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      BlocProvider<RegistrationBloc>.value(
        value: bloc,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RegisterScreen(),
        ),
      ),
    );
    await tester.tap(
      find.byType(DropdownButtonFormField<RegistrationVertical>),
    );
    await tester.pumpAndSettle();
    for (final String label in <String>[
      'Dairy Partner',
      'Dairy Delivery Driver',
      'Jhatka Partner',
      'Local Services Partner',
      'Real Estate Partner',
      'Stores Partner',
    ]) {
      expect(find.text(label).hitTestable(), findsOneWidget);
    }
    expect(find.text('Delivery Rider'), findsNothing);
    await tester.tap(find.text('Stores Partner').last);
    await tester.pumpAndSettle();
    expect(bloc.state.vertical, RegistrationVertical.stores);
    expect(find.text('Stores Partner'), findsOneWidget);
    expect(find.text('First name'), findsOneWidget);
    expect(find.text('Business model'), findsNothing);
    expect(
      requests,
      isEmpty,
      reason: 'Stores collects its outlet details after signup',
    );
  });

  for (final RegistrationVertical vertical in <RegistrationVertical>[
    RegistrationVertical.dairy,
    RegistrationVertical.jhatka,
    RegistrationVertical.stores,
  ]) {
    test(
      '${vertical.key} verifies OTP before signup and saves the correct session',
      () async {
        final _AuthRepository auth = _AuthRepository();
        final List<
          ({String endpoint, String method, Map<String, dynamic> body})
        >
        requests = [];
        final String prefix = switch (vertical) {
          RegistrationVertical.dairy => 'v1/dairy/auth/register',
          RegistrationVertical.jhatka => 'v1/jhatka/public/auth/register',
          _ => 'v1/stores/auth/register',
        };
        final RegistrationBloc bloc = RegistrationBloc(
          authRepository: auth,
          request:
              (
                String endpoint, {
                String method = 'POST',
                Map<String, dynamic>? body,
              }) async {
                requests.add((
                  endpoint: endpoint,
                  method: method,
                  body: body ?? {},
                ));
                if (method == 'GET') return const DioApiResponse.success('[]');
                if (endpoint == '$prefix/send_otp') {
                  return const DioApiResponse.success(
                    '{"id":"otp-1","provider":"app"}',
                  );
                }
                if (endpoint == 'v1/auth/verifyOTP') {
                  return const DioApiResponse.success('{}');
                }
                if (endpoint == '$prefix/partner') {
                  return DioApiResponse.success(
                    jsonEncode(<String, dynamic>{
                      'user': <String, dynamic>{
                        'id': 'u1',
                        'role': vertical.role ?? 'user',
                      },
                      'profile': null,
                      'verticals': <String>[vertical.key],
                      'tokens': <String, dynamic>{
                        'access': <String, dynamic>{
                          'token': 'access-1',
                          'expires': '2030-01-01',
                        },
                        'refresh': <String, dynamic>{
                          'token': 'refresh-1',
                          'expires': '2030-02-01',
                        },
                      },
                    }),
                  );
                }
                return const DioApiResponse.error(NetErrorType.notFound);
              },
        );
        addTearDown(bloc.close);
        await _dispatch(
          bloc,
          RegistrationVerticalSelected(vertical),
          (s) => s.vertical == vertical,
        );
        await _dispatch(
          bloc,
          const RegistrationFieldChanged(
            firstName: 'Test',
            lastName: 'Partner',
            mobile: '9876543210',
            email: 'partner@example.com',
            password: 'Password123',
            confirmPassword: 'Password123',
          ),
          (s) => s.mobile.isNotEmpty,
        );
        // Stale outlet fields must never leak into Stores' strict signup body.
        await _dispatch(
          bloc,
          RegistrationBusinessChanged(
            businessName: 'Test outlet',
            businessModel: 'direct',
            requestedBusinessModel: vertical == RegistrationVertical.dairy
                ? 'commission_partner'
                : '',
            city: 'city-1',
            locality: 'locality-1',
            addressLine1: 'Test street',
          ),
          (s) => s.businessName.isNotEmpty,
        );
        expect(bloc.state.canSubmit, isTrue);
        await _dispatch(
          bloc,
          const RegistrationSendOtp(),
          (s) => s.otpId != null,
        );
        expect(auth.access, isNull);
        await _dispatch(
          bloc,
          const RegistrationVerifyOtp('123456'),
          (s) => s.status == RegistrationStatus.success,
        );
        final posts = requests.where((r) => r.method == 'POST').toList();
        expect(posts.map((r) => r.endpoint), <String>[
          '$prefix/send_otp',
          'v1/auth/verifyOTP',
          '$prefix/partner',
        ]);
        expect(posts[1].body, <String, dynamic>{
          'id': 'otp-1',
          'provider': 'app',
          'otp': '123456',
        });
        expect(posts.last.body['id'], 'otp-1');
        if (vertical == RegistrationVertical.stores) {
          expect(
            posts.first.body.keys,
            unorderedEquals(<String>['countryCode', 'mobileNumber', 'locale']),
          );
          expect(
            posts.last.body.keys,
            unorderedEquals(<String>[
              'id',
              'locale',
              'remember',
              'userAgent',
              'firstName',
              'lastName',
              'countryCode',
              'mobile',
              'email',
              'password',
            ]),
          );
        } else {
          expect(posts.first.body['role'], vertical.role);
          expect(posts.last.body['role'], vertical.role);
          expect(posts.last.body['city'], 'city-1');
          expect(posts.last.body['locality'], 'locality-1');
          if (vertical == RegistrationVertical.jhatka) {
            expect(posts.last.body['addressLine1'], 'Test street');
          }
          if (vertical == RegistrationVertical.dairy) {
            expect(posts.last.body['requestedBusinessModel'], 'commission_partner');
            expect(posts.last.body.containsKey('businessModel'), isFalse);
          }
        }
        expect(auth.access, 'access-1');
        expect(auth.refresh, 'refresh-1');
        expect(auth.savedSession?.activeVertical, vertical.key);
        expect(auth.savedSession?.availableVerticals, <String>[vertical.key]);
      },
    );
  }

  test('Dairy driver signup requires and submits the one-time invite code', () async {
    final _AuthRepository auth = _AuthRepository();
    final List<({String endpoint, String method, Map<String, dynamic> body})>
        requests = [];
    final RegistrationBloc bloc = RegistrationBloc(
      authRepository: auth,
      request: (
        String endpoint, {
        String method = 'POST',
        Map<String, dynamic>? body,
      }) async {
        requests.add((endpoint: endpoint, method: method, body: body ?? {}));
        if (endpoint == DairyPartnerEndpoints.registerSendOtp) {
          return const DioApiResponse.success('{"id":"otp-driver","provider":"app"}');
        }
        if (endpoint == 'v1/auth/verifyOTP') {
          return const DioApiResponse.success('{}');
        }
        if (endpoint == DairyPartnerEndpoints.registerDriver) {
          return DioApiResponse.success(
            jsonEncode(<String, dynamic>{
              'user': <String, dynamic>{
                'id': 'driver-1',
                'role': 'dairyDriver',
              },
              'profile': null,
              'verticals': <String>['dairy'],
              'tokens': <String, dynamic>{
                'access': <String, dynamic>{
                  'token': 'driver-access',
                  'expires': '2030-01-01',
                },
                'refresh': <String, dynamic>{
                  'token': 'driver-refresh',
                  'expires': '2030-02-01',
                },
              },
            }),
          );
        }
        return const DioApiResponse.error(NetErrorType.notFound);
      },
    );
    addTearDown(bloc.close);

    await _dispatch(
      bloc,
      const RegistrationVerticalSelected(RegistrationVertical.dairyDriver),
      (s) => s.isDriver,
    );
    await _dispatch(
      bloc,
      const RegistrationFieldChanged(
        firstName: 'Test',
        lastName: 'Rider',
        mobile: '9876543210',
        email: 'rider@example.com',
        password: 'Password123',
        confirmPassword: 'Password123',
      ),
      (s) => s.mobile.isNotEmpty,
    );
    expect(bloc.state.canSubmit, isFalse);
    const String inviteCode = 'a1b2c3d4e5f6a7b8c9d0a1b2c3d4e5f6a1b2c3d4e5f6a7b8';
    await _dispatch(
      bloc,
      const RegistrationFieldChanged(inviteCode: inviteCode),
      (s) => s.inviteCode.isNotEmpty,
    );
    expect(bloc.state.canSubmit, isTrue);
    await _dispatch(bloc, const RegistrationSendOtp(), (s) => s.otpId != null);
    await _dispatch(
      bloc,
      const RegistrationVerifyOtp('123456'),
      (s) => s.status == RegistrationStatus.success,
    );

    expect(requests.map((r) => r.endpoint), <String>[
      DairyPartnerEndpoints.registerSendOtp,
      'v1/auth/verifyOTP',
      DairyPartnerEndpoints.registerDriver,
    ]);
    expect(requests.first.body['role'], 'dairyDriver');
    expect(requests.last.body['inviteCode'], inviteCode);
    expect(requests.last.body['mobile'], 9876543210);
    expect(requests.last.body.containsKey('city'), isFalse);
    expect(auth.savedSession?.activeRole, DairyAppRole.driver);
  });

  test(
    'changing vertical discards OTP and outlet fields, preserving identity',
    () async {
      final RegistrationBloc bloc = RegistrationBloc(
        request:
            (
              String endpoint, {
              String method = 'POST',
              Map<String, dynamic>? body,
            }) async => const DioApiResponse.success(
              '{"id":"otp-old","provider":"app"}',
            ),
      );
      addTearDown(bloc.close);
      await _dispatch(
        bloc,
        const RegistrationVerticalSelected(RegistrationVertical.stores),
        (s) => s.isStores,
      );
      await _dispatch(
        bloc,
        const RegistrationFieldChanged(firstName: 'Test', mobile: '9876543210'),
        (s) => s.mobile.isNotEmpty,
      );
      await _dispatch(
        bloc,
        const RegistrationSendOtp(),
        (s) => s.otpId != null,
      );
      await _dispatch(
        bloc,
        const RegistrationVerticalCleared(),
        (s) => s.vertical == null,
      );
      expect(bloc.state.otpId, isNull);
      expect(bloc.state.otpVerified, isFalse);
      expect(bloc.state.firstName, 'Test');
      expect(bloc.state.city, isEmpty);
      await _dispatch(
        bloc,
        const RegistrationSubmit(),
        (s) => s.status == RegistrationStatus.failure,
      );
      expect(bloc.state.alertMessage, 'Verify your mobile first');
    },
  );
}
