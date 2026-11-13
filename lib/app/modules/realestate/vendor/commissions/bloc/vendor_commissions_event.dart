/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_commissions_bloc.dart';

abstract class VendorCommissionsEvent {
  const VendorCommissionsEvent();
}

/// Loads the vendor's sale commissions.
class VendorCommissionsLoadRequested extends VendorCommissionsEvent {
  const VendorCommissionsLoadRequested();
}

/// Reloads the commissions.
class VendorCommissionsRefreshed extends VendorCommissionsEvent {
  const VendorCommissionsRefreshed();
}

/// Filters by commission status (empty = all).
class VendorCommissionsFilterChanged extends VendorCommissionsEvent {
  const VendorCommissionsFilterChanged(this.status);

  final String status;
}
