/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_analytics_bloc.dart';

abstract class VendorAnalyticsEvent {
  const VendorAnalyticsEvent();
}

/// Loads the vendor analytics snapshot.
class VendorAnalyticsLoadRequested extends VendorAnalyticsEvent {
  const VendorAnalyticsLoadRequested();
}

/// Reloads the snapshot.
class VendorAnalyticsRefreshed extends VendorAnalyticsEvent {
  const VendorAnalyticsRefreshed();
}
