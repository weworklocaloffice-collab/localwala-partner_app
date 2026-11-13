/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_dashboard_bloc.dart';

abstract class VendorDashboardEvent {
  const VendorDashboardEvent();
}

/// Loads the dashboard summary and the analytics counters together.
class VendorDashboardLoadEvent extends VendorDashboardEvent {
  const VendorDashboardLoadEvent();
}
