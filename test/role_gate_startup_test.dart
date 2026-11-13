import 'dart:async';

import 'package:partner/app/core/models/user_session_model.dart';
import 'package:partner/app/core/repositories/auth_repository.dart';
import 'package:partner/app/shell/role_gate/bloc/role_gate_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('opens the cached session when startup discovery does not respond', () async {
    final UserSessionModel cached = UserSessionModel.fromJson(<String, dynamic>{
      'id': 'cached-partner',
      'availableRoles': <String>['dairyPartner'],
      'activeRole': 'dairyPartner',
    });
    final RoleGateBloc bloc = RoleGateBloc(
      authRepository: _UnresponsiveAuthRepository(cached),
      startupDiscoveryTimeout: const Duration(milliseconds: 20),
    )..add(const RoleGateResolveEvent());

    try {
      final RoleGateState resolved = await bloc.stream
          .firstWhere((RoleGateState state) => state.status == RoleGateStatus.resolved)
          .timeout(const Duration(seconds: 1));

      expect(resolved.session?.id, 'cached-partner');
      expect(resolved.activeRole, DairyAppRole.partner);
    } finally {
      await bloc.close();
    }
  });
}

class _UnresponsiveAuthRepository extends AuthRepository {
  _UnresponsiveAuthRepository(this.cached);

  final UserSessionModel cached;

  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<UserSessionModel?> session() async => cached;

  @override
  Future<UserSessionModel?> fetchAvailableRoles() => Completer<UserSessionModel?>().future;

  @override
  Future<({List<String> verticals, List<String> shells})?> fetchAvailableVerticals() =>
      Completer<({List<String> verticals, List<String> shells})?>().future;
}
