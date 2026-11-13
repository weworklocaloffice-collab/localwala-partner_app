/*
 * WeWorkLocal
 * Hyperlocal Commerce, Delivery & Service Platform
 *
 * Copyright © 2026 WeWorkLocal.
 * All Rights Reserved.
 */

/// A city or locality row for the listing form's cascade dropdowns.
///
/// Served by the shared register endpoints (`getBasicDataDairyRequest`,
/// `localities_from_city`) — generic geo data, reused rather than
/// duplicated per vertical. Wire shape only (plan §12).
class RealEstateGeoOption {
  final String id;
  final String name;

  const RealEstateGeoOption({required this.id, required this.name});

  factory RealEstateGeoOption.fromJson(Map<String, dynamic> json) {
    return RealEstateGeoOption(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      name: (json['name'] ?? json['key'])?.toString() ?? '',
    );
  }
}
