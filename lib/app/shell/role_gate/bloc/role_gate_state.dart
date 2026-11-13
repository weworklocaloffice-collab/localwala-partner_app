part of 'role_gate_bloc.dart';

enum RoleGateStatus { initial, loading, resolved, failure }

class RoleGateState {
  final RoleGateStatus status;
  final UserSessionModel? session;
  final DairyAppRole activeRole;
  final int statusCode;
  final String alertMessage;

  const RoleGateState({
    this.status = RoleGateStatus.initial,
    this.session,
    this.activeRole = DairyAppRole.partner,
    this.statusCode = 0,
    this.alertMessage = '',
  });

  bool get isPartner => activeRole == DairyAppRole.partner;

  bool get isDriver => activeRole == DairyAppRole.driver;

  List<DairyAppRole> get availableRoles => session?.availableRoles ?? const <DairyAppRole>[];

  bool get canSwitchRole => availableRoles.length > 1;

  /// Shells the session may enter inside the realestate vertical.
  List<String> get availableRealEstateShells => session?.availableRealEstateShells ?? const <String>[];

  /// Active realestate shell id (`'vendor'`, `'executive'`), or empty when
  /// the session holds no realestate shell.
  String get activeRealEstateShell => session?.activeRealEstateShell ?? '';

  /// Verticals the session may enter (dairy always; realestate when a probe hit).
  List<String> get availableVerticals => session?.availableVerticals ?? const <String>['dairy'];

  /// The role that is not currently active, for a one-tap switch.
  DairyAppRole? get otherRole {
    for (final DairyAppRole role in availableRoles) {
      if (role != activeRole) return role;
    }
    return null;
  }

  RoleGateState copyWith({
    RoleGateStatus? status,
    UserSessionModel? session,
    DairyAppRole? activeRole,
    int? statusCode,
    String? alertMessage,
  }) {
    return RoleGateState(
      status: status ?? this.status,
      session: session ?? this.session,
      activeRole: activeRole ?? this.activeRole,
      statusCode: statusCode ?? this.statusCode,
      alertMessage: alertMessage ?? this.alertMessage,
    );
  }
}