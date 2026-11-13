part of 'role_gate_bloc.dart';

abstract class RoleGateEvent {
  const RoleGateEvent();
}

/// Reads the persisted session and asks the API which roles it may hold.
class RoleGateResolveEvent extends RoleGateEvent {
  const RoleGateResolveEvent();
}

/// Moves the session to the other shell without re-authenticating.
class RoleGateSwitchEvent extends RoleGateEvent {
  final DairyAppRole role;

  const RoleGateSwitchEvent(this.role);
}

/// Convenience event used by the rider shell's app bar to jump back to the
/// outlet shell without going through the role gate screen.
class RoleGateSwitchToPartnerEvent extends RoleGateEvent {
  const RoleGateSwitchToPartnerEvent();
}

/// Moves the session to another realestate shell without re-authenticating.
///
/// Client-side only: unlike dairy roles there is no server switch-role
/// call — the server enforces rights per request regardless of which
/// shell renders. Unknown shells are ignored by the handler.
class RoleGateSwitchRealEstateShellEvent extends RoleGateEvent {
  final String shell;

  const RoleGateSwitchRealEstateShellEvent(this.shell);
}

/// Enters the vertical chosen in `shell/vertical_picker/`.
///
/// The vertical picker only appears when the account spans more than one
/// vertical; picking one persists it on the session and lets the app shell
/// dispatch to that module.
class RoleGatePickVerticalEvent extends RoleGateEvent {
  final String vertical;

  const RoleGatePickVerticalEvent(this.vertical);
}