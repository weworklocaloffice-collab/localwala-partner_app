/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

part of 'vendor_profile_bloc.dart';

abstract class VendorProfileEvent {
  const VendorProfileEvent();
}

/// Loads the vendor's own record.
class VendorProfileLoadRequested extends VendorProfileEvent {
  const VendorProfileLoadRequested();
}

/// Reloads the record.
class VendorProfileRefreshed extends VendorProfileEvent {
  const VendorProfileRefreshed();
}

/// Submits the vendor for review (DRAFT/CHANGES_REQUIRED -> PENDING).
class VendorProfileSubmitRequested extends VendorProfileEvent {
  const VendorProfileSubmitRequested();
}
