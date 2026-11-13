/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'executive_visits_bloc.dart';

abstract class ExecutiveVisitsEvent {
  const ExecutiveVisitsEvent();
}

/// Switches the active tab, loading its first page unless cached.
class ExecutiveVisitsTabSelected extends ExecutiveVisitsEvent {
  final String tabId;

  const ExecutiveVisitsTabSelected(this.tabId);
}

/// Appends the next page of the active tab, if any remains.
class ExecutiveVisitsNextPage extends ExecutiveVisitsEvent {
  const ExecutiveVisitsNextPage();
}

/// Reloads the active tab from page one.
class ExecutiveVisitsRefreshed extends ExecutiveVisitsEvent {
  const ExecutiveVisitsRefreshed();
}

/// ASSIGNED → ACCEPTED.
class ExecutiveVisitAccept extends ExecutiveVisitsEvent {
  final String visitId;

  const ExecutiveVisitAccept(this.visitId);
}

/// Geofenced check-in with the device position (BR-08).
class ExecutiveVisitCheckIn extends ExecutiveVisitsEvent {
  final String visitId;
  final double lng;
  final double lat;

  const ExecutiveVisitCheckIn(this.visitId, {required this.lng, required this.lat});
}

/// Completes the visit, optionally with closing notes.
class ExecutiveVisitComplete extends ExecutiveVisitsEvent {
  final String visitId;
  final String? notes;

  const ExecutiveVisitComplete(this.visitId, {this.notes});
}

/// Cancels the visit with a mandatory reason.
class ExecutiveVisitCancel extends ExecutiveVisitsEvent {
  final String visitId;
  final String reason;

  const ExecutiveVisitCancel(this.visitId, {required this.reason});
}

/// Appends free-text notes without changing state.
class ExecutiveVisitAddNotes extends ExecutiveVisitsEvent {
  final String visitId;
  final String notes;

  const ExecutiveVisitAddNotes(this.visitId, {required this.notes});
}

/// Records structured customer interest (BR-09): closed level +
/// closed reason, free text only via reasonText for OTHER.
class ExecutiveVisitRecordInterest extends ExecutiveVisitsEvent {
  final String visitId;
  final String level;
  final String reason;
  final String? reasonText;

  const ExecutiveVisitRecordInterest(
    this.visitId, {
    required this.level,
    required this.reason,
    this.reasonText,
  });
}

/// Schedules a follow-up on the visit's lead.
class ExecutiveVisitScheduleFollowUp extends ExecutiveVisitsEvent {
  final String visitId;
  final String leadId;
  final DateTime nextFollowUpAt;
  final String mode;
  final String? notes;

  const ExecutiveVisitScheduleFollowUp(
    this.visitId, {
    required this.leadId,
    required this.nextFollowUpAt,
    required this.mode,
    this.notes,
  });
}
