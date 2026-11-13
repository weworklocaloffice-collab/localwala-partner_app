/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vertical_picker_bloc.dart';

abstract class VerticalPickerEvent {
  const VerticalPickerEvent();
}

/// Builds the option list from the session's available verticals,
/// intersected with the verticals this build can actually render.
class VerticalPickerLoadEvent extends VerticalPickerEvent {
  final UserSessionModel session;

  const VerticalPickerLoadEvent(this.session);
}

/// Records the tapped option. Persistence is the role gate's job —
/// the view reports the pick through `onPicked`, which raises
/// `RoleGatePickVerticalEvent`.
class VerticalPickerSelectEvent extends VerticalPickerEvent {
  final String vertical;

  const VerticalPickerSelectEvent(this.vertical);
}
