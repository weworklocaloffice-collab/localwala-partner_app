/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_customers_bloc.dart';

abstract class VendorCustomersEvent {
  const VendorCustomersEvent();
}

/// Loads the first page.
class VendorCustomersLoadRequested extends VendorCustomersEvent {
  const VendorCustomersLoadRequested();
}

/// Appends the next page, if any remains.
class VendorCustomersNextPage extends VendorCustomersEvent {
  const VendorCustomersNextPage();
}

/// Reloads from page one.
class VendorCustomersRefreshed extends VendorCustomersEvent {
  const VendorCustomersRefreshed();
}
