/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_listings_bloc.dart';

abstract class VendorListingsEvent {
  const VendorListingsEvent();
}

/// Switches the active tab, loading its first page unless cached.
class VendorListingsTabSelected extends VendorListingsEvent {
  final String tabId;

  const VendorListingsTabSelected(this.tabId);
}

/// Appends the next page of the active tab, if any remains.
class VendorListingsNextPage extends VendorListingsEvent {
  const VendorListingsNextPage();
}

/// Reloads the active tab from page one.
class VendorListingsRefreshed extends VendorListingsEvent {
  const VendorListingsRefreshed();
}
