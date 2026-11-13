/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'lead_detail_bloc.dart';

abstract class LeadDetailEvent {
  const LeadDetailEvent();
}

/// Loads the lead with its crossroads (visits, follow-ups, hold, sale,
/// latest loan status) in one call.
class LeadDetailLoadRequested extends LeadDetailEvent {
  final String leadId;

  const LeadDetailLoadRequested(this.leadId);
}

/// Reloads everything.
class LeadDetailRefreshed extends LeadDetailEvent {
  const LeadDetailRefreshed();
}
