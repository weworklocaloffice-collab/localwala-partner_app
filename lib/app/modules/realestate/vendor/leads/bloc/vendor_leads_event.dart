/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_leads_bloc.dart';

abstract class VendorLeadsEvent {
  const VendorLeadsEvent();
}

/// Switches the active tab, loading its first page unless cached.
class VendorLeadsTabSelected extends VendorLeadsEvent {
  final String tabId;

  const VendorLeadsTabSelected(this.tabId);
}

/// Appends the next page of the active tab, if any remains.
class VendorLeadsNextPage extends VendorLeadsEvent {
  const VendorLeadsNextPage();
}

/// Reloads the active tab from page one.
class VendorLeadsRefreshed extends VendorLeadsEvent {
  const VendorLeadsRefreshed();
}
