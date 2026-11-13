/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_packages_bloc.dart';

abstract class VendorPackagesEvent {
  const VendorPackagesEvent();
}

/// Loads the catalogue and the entitlement balance together.
class VendorPackagesLoadRequested extends VendorPackagesEvent {
  const VendorPackagesLoadRequested();
}

/// Reloads both.
class VendorPackagesRefreshed extends VendorPackagesEvent {
  const VendorPackagesRefreshed();
}
