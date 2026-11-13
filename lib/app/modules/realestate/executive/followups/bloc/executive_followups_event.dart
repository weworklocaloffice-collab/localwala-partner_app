/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'executive_followups_bloc.dart';

abstract class ExecutiveFollowUpsEvent {
  const ExecutiveFollowUpsEvent();
}

/// Loads the first page of follow-ups.
class ExecutiveFollowUpsLoad extends ExecutiveFollowUpsEvent {
  const ExecutiveFollowUpsLoad();
}

/// Appends the next page, if any remains.
class ExecutiveFollowUpsNextPage extends ExecutiveFollowUpsEvent {
  const ExecutiveFollowUpsNextPage();
}

/// Reloads from page one.
class ExecutiveFollowUpsRefreshed extends ExecutiveFollowUpsEvent {
  const ExecutiveFollowUpsRefreshed();
}

/// Marks one follow-up complete.
class ExecutiveFollowUpComplete extends ExecutiveFollowUpsEvent {
  final String followUpId;

  const ExecutiveFollowUpComplete(this.followUpId);
}
