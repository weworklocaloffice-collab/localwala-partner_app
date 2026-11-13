/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'executive_today_bloc.dart';

abstract class ExecutiveTodayEvent {
  const ExecutiveTodayEvent();
}

/// Loads identity plus dashboard aggregates together.
class ExecutiveTodayLoad extends ExecutiveTodayEvent {
  const ExecutiveTodayLoad();
}
