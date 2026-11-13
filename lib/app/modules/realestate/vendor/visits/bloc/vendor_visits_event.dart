/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_visits_bloc.dart';

abstract class VendorVisitsEvent {
  const VendorVisitsEvent();
}

/// Switches the active tab, loading its first page unless cached.
class VendorVisitsTabSelected extends VendorVisitsEvent {
  final String tabId;

  const VendorVisitsTabSelected(this.tabId);
}

/// Appends the next page of the active tab, if any remains.
class VendorVisitsNextPage extends VendorVisitsEvent {
  const VendorVisitsNextPage();
}

/// Reloads the active tab from page one.
class VendorVisitsRefreshed extends VendorVisitsEvent {
  const VendorVisitsRefreshed();
}
